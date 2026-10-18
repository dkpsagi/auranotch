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

                    // Mascot Icon (Waving 3D Holographic Character)
                    mascotAvatarView
                        .scaleEffect(mascotWiggle ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: mascotWiggle)
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
                        featureRow(icon: "chart.line.uptrend.xyaxis", title: "Unified Sales & Revenue Tracker", color: .green)
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
                // Input Row: License Key Field + Activate Button
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

                // "No license? Get AuraNotch ↗"
                HStack(spacing: 4) {
                    Text("No license?")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))

                    Button(action: {
                        if let url = URL(string: "https://auranotch.app/#pricing") {
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
                    licenseKeyInput = "AURA-PRO-2026-LIFETIME-VIP"
                    _ = licenseMgr.activateKey(licenseKeyInput)
                }) {
                    Text("Quick-Fill Lifetime Demo Key")
                        .font(.system(size: 9))
                        .foregroundColor(.purple.opacity(0.8))
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
    }

    // --- 3D MASCOT AVATAR (Adorable Blue Character Waving) ---
    private var mascotAvatarView: some View {
        ZStack {
            // Ambient Aura Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.blue.opacity(0.4), Color.purple.opacity(0.2), Color.clear],
                        center: .center,
                        startRadius: 5,
                        endRadius: 40
                    )
                )
                .frame(width: 80, height: 80)

            // Mascot Body (Layered Glossy Blue Sphere & Ears)
            ZStack {
                // Ears / Antennas
                HStack(spacing: 36) {
                    Circle()
                        .fill(LinearGradient(colors: [Color.cyan, Color.blue], startPoint: .top, endPoint: .bottom))
                        .frame(width: 16, height: 16)
                    Circle()
                        .fill(LinearGradient(colors: [Color.cyan, Color.blue], startPoint: .top, endPoint: .bottom))
                        .frame(width: 16, height: 16)
                }
                .offset(y: -22)

                // Head
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.25, green: 0.65, blue: 1.0), Color(red: 0.10, green: 0.40, blue: 0.95)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 50)
                    .shadow(color: Color.blue.opacity(0.4), radius: 6, x: 0, y: 4)

                // White Face Visor
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.92))
                    .frame(width: 44, height: 32)

                // Big Kawaii Eyes
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color(red: 0.05, green: 0.15, blue: 0.35))
                        .frame(width: 7, height: 7)
                        .overlay(
                            Circle().fill(Color.white).frame(width: 2.5, height: 2.5).offset(x: -1, y: -1)
                        )
                    Circle()
                        .fill(Color(red: 0.05, green: 0.15, blue: 0.35))
                        .frame(width: 7, height: 7)
                        .overlay(
                            Circle().fill(Color.white).frame(width: 2.5, height: 2.5).offset(x: -1, y: -1)
                        )
                }
                .offset(y: -2)

                // Smile
                Circle()
                    .trim(from: 0.15, to: 0.85)
                    .stroke(Color(red: 0.05, green: 0.15, blue: 0.35), lineWidth: 1.5)
                    .frame(width: 9, height: 7)
                    .rotationEffect(.degrees(180))
                    .offset(y: 8)

                // Waving Hand
                Circle()
                    .fill(Color.cyan)
                    .frame(width: 14, height: 14)
                    .offset(x: 32, y: -14)
                    .rotationEffect(.degrees(mascotWiggle ? 15 : -10))
            }
        }
        .frame(height: 70)
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
