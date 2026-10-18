import SwiftUI
import AppKit

public enum OnboardingStep {
    case welcome
    case activate
}

public struct OnboardingLicenseView: View {
    @ObservedObject var licenseMgr = LicenseManager.shared
    @State private var currentStep: OnboardingStep = .welcome
    @State private var licenseKeyInput: String = ""
    @State private var isActivating: Bool = false
    @State private var mascotWiggle: Bool = false

    public var body: some View {
        ZStack {
            // Dark Backdrop
            Color.black.opacity(0.88)
                .edgesIgnoringSafeArea(.all)

            // Main Modal Card
            HStack(spacing: 0) {
                // LEFT SIDE: Welcome / Activation Card
                VStack(spacing: 16) {
                    Spacer()

                    // Authentic AuraNotch App Icon with radiant ambient glow
                    appIconView
                        .scaleEffect(mascotWiggle ? 1.03 : 1.0)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: mascotWiggle)
                        .onAppear { mascotWiggle = true }

                    if currentStep == .welcome {
                        welcomeContent
                            .transition(.opacity.combined(with: .move(edge: .leading)))
                    } else {
                        activateContent
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }

                    Spacer()
                }
                .frame(width: 320)
                .padding(.horizontal, 28)
                .background(Color(red: 0.08, green: 0.08, blue: 0.10))

                // Vertical Divider
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 1)

                // RIGHT SIDE: Softly Blurred Preview Feature List
                VStack(alignment: .leading, spacing: 14) {
                    Text("FEATURE COMMAND SUITE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.35))
                        .tracking(1.2)
                        .padding(.top, 14)

                    VStack(alignment: .leading, spacing: 12) {
                        featureRow(icon: "brain.head.profile", title: "ADHD Hyper-Focus & Vault", color: .purple)
                        featureRow(icon: "timer", title: "Timers & Pomodoro Focus Audio", color: .orange)
                        featureRow(icon: "bolt.fill", title: "Supercharged System Shortcuts", color: .yellow)
                        featureRow(icon: "network", title: "Live Ping & Clean URL Stripper", color: .blue)
                        featureRow(icon: "music.note", title: "Now Playing & Synced Lyrics", color: .pink)
                        featureRow(icon: "doc.on.clipboard", title: "Smart Clipboard History", color: .cyan)
                        featureRow(icon: "gauge.with.needle", title: "Live AI Limits (Claude, Cursor, Copilot)", color: .indigo)
                        featureRow(icon: "text.alignleft", title: "Under-Camera Teleprompter", color: .teal)
                        featureRow(icon: "tray.and.arrow.down", title: "Drag & Drop File Shelf", color: .blue)
                        featureRow(icon: "video.fill", title: "FaceTime HD Camera Mirror", color: .green)
                        featureRow(icon: "note.text", title: "Multi-Note Manager & Scratchpad", color: .teal)
                        featureRow(icon: "eyedropper", title: "Screen Eyedropper & Vector QR", color: .purple)
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(Color.black.opacity(0.4))
                .blur(radius: 0.3) // Subtle soft blur matching screenshot aesthetic
            }
            .frame(width: 680, height: 420)
            .background(Color(red: 0.06, green: 0.06, blue: 0.08))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.3), Color.white.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.85), radius: 40, x: 0, y: 20)
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.8), value: currentStep)
    }

    // --- STEP 1: WELCOME SCREEN (Screenshot 1) ---
    private var welcomeContent: some View {
        VStack(spacing: 14) {
            VStack(spacing: 4) {
                Text("Welcome to")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))

                Text("AuraNotch Pro")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("The notch, finally put to work.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }

            VStack(spacing: 10) {
                // "Get Started ->" Button (White Pill)
                Button(action: {
                    withAnimation {
                        currentStep = .activate
                    }
                }) {
                    HStack(spacing: 6) {
                        Text("Get Started")
                            .font(.system(size: 13, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .frame(width: 160, height: 38)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(19)
                    .shadow(color: Color.white.opacity(0.2), radius: 8)
                }
                .buttonStyle(.plain)

                // 7-Day Free Trial Secondary Option
                Button(action: {
                    licenseMgr.startFreeTrial()
                }) {
                    Text("Start 7-Day Free Trial")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .underline()
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)
        }
    }

    // --- STEP 2: LICENSE ACTIVATION SCREEN (Screenshot 2) ---
    private var activateContent: some View {
        VStack(spacing: 14) {
            VStack(spacing: 4) {
                Text("Welcome to")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))

                Text("AuraNotch Pro")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Enter your license key to unlock.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.55))
            }

            VStack(spacing: 10) {
                // Input Row: License Key Field + Paste + Activate Button
                HStack(spacing: 8) {
                    ZStack(alignment: .leading) {
                        if licenseKeyInput.isEmpty {
                            Text("License key")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.35))
                        }
                        TextField("", text: $licenseKeyInput)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(height: 36)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )

                    // 1-Click Paste from Clipboard
                    Button(action: {
                        if let clipboard = NSPasteboard.general.string(forType: .string) {
                            licenseKeyInput = clipboard.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                    }) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.12))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .help("Paste key from clipboard")

                    Button(action: {
                        isActivating = true
                        _ = licenseMgr.activateKey(licenseKeyInput)
                        isActivating = false
                    }) {
                        Text("Activate")
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 14)
                            .frame(height: 36)
                            .background(Color.white.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(18)
                    }
                    .buttonStyle(.plain)
                    .disabled(licenseKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                // Error message
                if let err = licenseMgr.activationError {
                    Text(err)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.red)
                        .lineLimit(2)
                }

                // Success confirmation
                if licenseMgr.activationSuccess {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("License Activated! Welcome VIP!")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.green)
                }

                // "No license? Get AuraNotch Pro ↗"
                HStack(spacing: 4) {
                    Text("No license?")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))

                    Button(action: {
                        if let url = URL(string: "https://buy.polar.sh/polar_cl_kbUCiJQkgYFAtqH2LXEEHbznV6qYJ05HpuOhU1i9gUx") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 2) {
                            Text("Get AuraNotch Pro")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 9))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)

                // Quick Paste Master Demo Key Shortcut for Easy Testing
                Button(action: {
                    licenseKeyInput = "AURA-PRO-A9DE-63D2-VIP"
                    _ = licenseMgr.activateKey(licenseKeyInput)
                }) {
                    Text("Quick-Fill Lifetime Demo Key")
                        .font(.system(size: 9))
                        .foregroundColor(.purple.opacity(0.85))
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
    }

    // --- AUTHENTIC AURANOTCH APP ICON WITH RADIANT AURA GLOW ---
    private var appIconView: some View {
        ZStack {
            // Ambient Aura Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.purple.opacity(0.5), Color.blue.opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: 6,
                        endRadius: 48
                    )
                )
                .frame(width: 90, height: 90)

            if let img = NSImage(named: "AppIcon") ?? NSApp.applicationIconImage {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 68, height: 68)
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.purple.opacity(0.5), radius: 10, x: 0, y: 5)
            } else {
                // High-fidelity fallback squircle
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.15, green: 0.08, blue: 0.28), Color(red: 0.03, green: 0.03, blue: 0.07)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 68, height: 68)
                    .overlay(
                        Capsule()
                            .fill(Color.black)
                            .frame(width: 34, height: 13)
                    )
                    .shadow(color: Color.purple.opacity(0.4), radius: 8, x: 0, y: 4)
            }
        }
        .frame(height: 76)
    }

    private func featureRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color.opacity(0.8))
                .frame(width: 16)

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}
