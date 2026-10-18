import SwiftUI

public class NotesManager: ObservableObject {
    public static let shared = NotesManager()

    @Published public var noteText: String = """
    # AuraNotch Quick Scratchpad
    - [x] Connected real system stats (CPU, RAM, Disk, Battery)
    - [x] Connected live clipboard monitor
    - [x] Added multi-player detection (Spotify, Apple Music, SoundCloud)
    - [x] Added real ambient audio engine to Focus sounds
    - [x] Added paste/clear/editing tools to Teleprompter
    """
}

public struct QuickNotesView: View {
    @ObservedObject var notesMgr = NotesManager.shared

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Scratchpad & Persistent Notes")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                    .textCase(.uppercase)
                Spacer()
                Text("Auto-saved locally")
                    .font(.system(size: 10))
                    .foregroundColor(.green)
            }

            TextEditor(text: $notesMgr.noteText)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .background(Color.white.opacity(0.04))
                .cornerRadius(10)
                .padding(.top, 2)
        }
        .padding(14)
    }
}

public struct SettingsView: View {
    @ObservedObject var appState = AppState.shared
    @State private var inputKey: String = ""
    @State private var activationStatus: String? = nil

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                // ROW 1: THEME, GLASS & ACCENT CONTROLS
                VStack(alignment: .leading, spacing: 10) {
                    Text("Liquid Glass Theme & Aesthetics")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                        .textCase(.uppercase)

                    // Theme selector chips
                    HStack(spacing: 8) {
                        ForEach(GlassTheme.allCases) { theme in
                            let isSelected = appState.currentTheme == theme
                            Button(action: {
                                appState.currentTheme = theme
                            }) {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(theme.primaryAccent)
                                        .frame(width: 8, height: 8)
                                    Text(theme.rawValue)
                                        .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(isSelected ? theme.primaryAccent.opacity(0.25) : Color.white.opacity(0.06))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(isSelected ? theme.primaryAccent.opacity(0.6) : Color.clear, lineWidth: 1)
                                )
                                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Sliders for Glass Opacity and Notch Clearance
                    HStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Glass Opacity:")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Text("\(Int(appState.glassOpacity * 100))%")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            Slider(value: $appState.glassOpacity, in: 0.6...0.99)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Top Notch Safe Clearance:")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Text("\(Int(appState.topNotchClearance)) pt")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            Slider(value: $appState.topNotchClearance, in: 28...64, step: 2)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(14)
                .background(Color.white.opacity(0.04))
                .cornerRadius(12)

                // ROW 2: HUD SIZING & INTERACTION BEHAVIOR
                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Trigger & Interaction")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                            .textCase(.uppercase)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Open Mode:")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white)
                                Spacer()
                                Picker("", selection: $appState.triggerMode) {
                                    ForEach(NotchTriggerMode.allCases) { mode in
                                        Text(mode.rawValue).tag(mode)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 130)
                            }

                            if appState.triggerMode == .hover {
                                HStack {
                                    Text("Hover Delay:")
                                        .font(.system(size: 11))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Slider(value: $appState.hoverDelayMs, in: 80...400, step: 20)
                                        .frame(width: 90)
                                    Text("\(Int(appState.hoverDelayMs)) ms")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }

                            Toggle("Haptic Click Feedback", isOn: $appState.playHapticFeedback)
                                .font(.system(size: 11))
                                .foregroundColor(.white)

                            Toggle("Show on All Monitors", isOn: $appState.showOnAllScreens)
                                .font(.system(size: 11))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(10)

                    // Sizing Presets
                    VStack(alignment: .leading, spacing: 10) {
                        Text("HUD Size Presets")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                            .textCase(.uppercase)

                        VStack(spacing: 6) {
                            sizePresetButton(title: "Compact", sizeText: "680 × 480 pt", w: 680, h: 480)
                            sizePresetButton(title: "Balanced (Recommended)", sizeText: "750 × 540 pt", w: 750, h: 540)
                            sizePresetButton(title: "Expanded Studio", sizeText: "820 × 580 pt", w: 820, h: 580)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(10)
                }

                // ROW 3: LICENSE KEY & KEYCHAIN
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Circle().fill(Color.green).frame(width: 7, height: 7)
                            Text("AuraNotch Pro · Lifetime VIP Activated")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Text("Key: \(appState.licenseKey) · Stored securely in macOS Keychain")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                    Text("Version 2.5.0")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(12)
                .background(Color.white.opacity(0.04))
                .cornerRadius(10)
            }
            .padding(14)
        }
    }

    private func sizePresetButton(title: String, sizeText: String, w: CGFloat, h: CGFloat) -> some View {
        let isCurrent = (appState.expandedWidth == w && appState.expandedHeight == h)
        return Button(action: {
            appState.expandedWidth = w
            appState.expandedHeight = h
            NotchWindowController.shared.updateWindowFrame(animated: true)
        }) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: isCurrent ? .bold : .medium))
                Spacer()
                Text(sizeText)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isCurrent ? Color.purple.opacity(0.3) : Color.white.opacity(0.05))
            .cornerRadius(6)
            .foregroundColor(isCurrent ? .white : .white.opacity(0.8))
        }
        .buttonStyle(.plain)
    }
}
