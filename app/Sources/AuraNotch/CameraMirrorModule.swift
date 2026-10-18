import SwiftUI
import AVFoundation
import AppKit

public class CameraPreviewNSView: NSView {
    public var previewLayer: AVCaptureVideoPreviewLayer?

    public init(session: AVCaptureSession) {
        super.init(frame: .zero)
        self.wantsLayer = true
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        if let conn = layer.connection, conn.isVideoMirroringSupported {
            conn.automaticallyAdjustsVideoMirroring = false
            conn.isVideoMirrored = true
        }
        self.layer = layer
        self.previewLayer = layer
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layout() {
        super.layout()
        previewLayer?.frame = self.bounds
    }
}

public struct CameraPreviewView: NSViewRepresentable {
    public let session: AVCaptureSession

    public init(session: AVCaptureSession) {
        self.session = session
    }

    public func makeNSView(context: Context) -> CameraPreviewNSView {
        return CameraPreviewNSView(session: session)
    }

    public func updateNSView(_ nsView: CameraPreviewNSView, context: Context) {
        nsView.previewLayer?.frame = nsView.bounds
    }
}

public class CameraMirrorManager: ObservableObject {
    public static let shared = CameraMirrorManager()

    @Published public var isCameraActive: Bool = false
    @Published public var cameraName: String = "FaceTime HD Camera"
    @Published public var hasPermission: Bool = false
    @Published public var isInitializing: Bool = false
    @Published public var errorMessage: String? = nil

    public let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "app.auranotch.camera.session")
    private var isConfigured: Bool = false

    private init() {
        checkPermission()
    }

    public func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.hasPermission = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.hasPermission = granted
                }
            }
        default:
            self.hasPermission = false
        }
    }

    public func toggleCamera() {
        if isCameraActive {
            stopCamera()
        } else {
            startCamera()
        }
    }

    public func startCamera() {
        guard !isCameraActive else { return }
        isInitializing = true
        errorMessage = nil

        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.hasPermission = granted
                    if granted {
                        self?.configureAndRun()
                    } else {
                        self?.isInitializing = false
                        self?.errorMessage = "Camera permission denied."
                    }
                }
            }
        } else if status == .authorized {
            self.hasPermission = true
            configureAndRun()
        } else {
            self.isInitializing = false
            self.hasPermission = false
            self.errorMessage = "Camera access denied. Please grant permission in System Settings > Privacy & Security > Camera."
        }
    }

    private func configureAndRun() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.isConfigured {
                self.session.beginConfiguration()
                self.session.sessionPreset = .high

                let discovery = AVCaptureDevice.DiscoverySession(
                    deviceTypes: [.builtInWideAngleCamera, .external],
                    mediaType: .video,
                    position: .unspecified
                )

                if let device = discovery.devices.first ?? AVCaptureDevice.default(for: .video) {
                    DispatchQueue.main.async {
                        self.cameraName = device.localizedName
                    }
                    if let input = try? AVCaptureDeviceInput(device: device), self.session.canAddInput(input) {
                        self.session.addInput(input)
                        self.isConfigured = true
                    }
                }
                self.session.commitConfiguration()
            }

            if self.isConfigured && !self.session.isRunning {
                self.session.startRunning()
            }

            DispatchQueue.main.async {
                self.isCameraActive = true
                self.isInitializing = false
            }
        }
    }

    public func stopCamera() {
        guard isCameraActive else { return }
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
            DispatchQueue.main.async {
                self.isCameraActive = false
                self.isInitializing = false
            }
        }
    }
}

public struct CameraMirrorView: View {
    @ObservedObject var appState = AppState.shared
    @ObservedObject var mirror = CameraMirrorManager.shared

    public var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.85))
                    .frame(height: 310)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                mirror.isCameraActive ? appState.currentTheme.primaryAccent.opacity(0.5) : Color.white.opacity(0.12),
                                lineWidth: 1.2
                            )
                    )

                if mirror.isCameraActive {
                    // REAL LIVE CAMERA HARDWARE FEED
                    CameraPreviewView(session: mirror.session)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .frame(height: 308)
                        .overlay(
                            // Subtle mirror crosshair overlay
                            VStack {
                                HStack {
                                    HStack(spacing: 5) {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 7, height: 7)
                                        Text("LIVE PREVIEW")
                                            .font(.system(size: 9, weight: .heavy))
                                            .foregroundColor(.white)
                                    }
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(Color.black.opacity(0.65))
                                    .cornerRadius(5)

                                    Spacer()

                                    Text(mirror.cameraName)
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 3)
                                        .background(Color.black.opacity(0.65))
                                        .cornerRadius(5)
                                }
                                .padding(10)
                                Spacer()
                            }
                        )
                } else if mirror.isInitializing {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Connecting to camera hardware...")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                } else {
                    // Turn On Screen
                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(appState.currentTheme.primaryAccent.opacity(0.2))
                                .frame(width: 72, height: 72)

                            Image(systemName: "camera.fill")
                                .font(.system(size: 30))
                                .foregroundColor(appState.currentTheme.primaryAccent)
                        }

                        VStack(spacing: 4) {
                            Text("Under-Notch Quick Camera Mirror")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)

                            Text("Inspect lighting, angle, and appearance instantly right below the camera lens.")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.55))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 320)
                        }

                        if let err = mirror.errorMessage {
                            Text(err)
                                .font(.system(size: 10))
                                .foregroundColor(.red.opacity(0.8))
                                .padding(.horizontal, 16)
                        }

                        Button(action: { mirror.startCamera() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "video.fill")
                                Text("Open Camera Mirror")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(appState.currentTheme.primaryAccent)
                            .foregroundColor(.white)
                            .cornerRadius(9)
                            .shadow(color: appState.currentTheme.primaryAccent.opacity(0.4), radius: 8, x: 0, y: 3)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Bottom controls
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: mirror.isCameraActive ? "video.fill" : "video.slash.fill")
                        .foregroundColor(mirror.isCameraActive ? .green : .white.opacity(0.4))
                        .font(.system(size: 11))
                    Text(mirror.cameraName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                if mirror.isCameraActive {
                    Button(action: { mirror.stopCamera() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "power")
                            Text("Turn Off")
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.red.opacity(0.9))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.12))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(14)
        .onDisappear {
            // Guarantee camera hardware LED turns off when switching tabs or closing
            mirror.stopCamera()
        }
    }
}
