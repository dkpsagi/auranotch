import SwiftUI
import AVFoundation

public class CameraMirrorManager: ObservableObject {
    public static let shared = CameraMirrorManager()

    @Published public var isCameraActive: Bool = false
    @Published public var cameraName: String = "FaceTime HD Camera"

    public func toggleCamera() {
        isCameraActive.toggle()
    }
}

public struct CameraMirrorView: View {
    @ObservedObject var mirror = CameraMirrorManager.shared

    public var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.black.opacity(0.8))
                    .frame(height: 240)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )

                if mirror.isCameraActive {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 72))
                            .foregroundColor(.white.opacity(0.85))

                        Text("Live Camera Feed Active")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)

                        Text("Checking lighting and posture before calls...")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 38))
                            .foregroundColor(.white.opacity(0.3))

                        Text("Click to turn on Quick Camera Mirror")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))

                        Button(action: { mirror.toggleCamera() }) {
                            Text("Open Mirror")
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 7)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack {
                Image(systemName: "video.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 11))
                Text(mirror.cameraName)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                if mirror.isCameraActive {
                    Button(action: { mirror.toggleCamera() }) {
                        Text("Turn Off")
                            .font(.system(size: 11))
                            .foregroundColor(.red.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(16)
    }
}
