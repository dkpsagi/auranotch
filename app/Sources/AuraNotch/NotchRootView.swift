import SwiftUI

public struct NotchRootView: View {
    @ObservedObject var appState = AppState.shared
    @ObservedObject var media = MediaManager.shared
    @ObservedObject var timerMgr = TimerManager.shared
    @ObservedObject var soundEngine = FocusSoundSynthesizer.shared
    @ObservedObject var licenseMgr = LicenseManager.shared

    public var body: some View {
        ZStack(alignment: .top) {
            if appState.isExpanded {
                expandedGlassNotchView
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.96, anchor: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.96, anchor: .top))
                    ))
            } else {
                closedPillView
                    .transition(.opacity)
            }

            // Onboarding & License Key Activation Modal
            if licenseMgr.showActivationModal {
                OnboardingLicenseView()
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: appState.isExpanded)
        .animation(.easeInOut(duration: 0.16), value: appState.activeTab)
    }

    // Closed Pill View (Hugs physical camera notch or draws floating island)
    private var closedPillView: some View {
        HStack(spacing: 8) {
            // Left Live Indicator
            if media.hasActiveMedia && media.currentSong.isPlaying {
                HStack(spacing: 2.5) {
                    ForEach(0..<3) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(appState.currentTheme.primaryAccent)
                            .frame(width: 2.5, height: CGFloat([8, 14, 10][i]))
                    }
                }
                .padding(.leading, 10)
            } else if soundEngine.isPlaying {
                Image(systemName: "headphones")
                    .font(.system(size: 10))
                    .foregroundColor(.orange)
                    .padding(.leading, 10)
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.leading, 10)
            }

            Spacer()

            // Center Dynamic Activity Indicator
            if timerMgr.isRunning {
                HStack(spacing: 4) {
                    Circle().fill(Color.orange).frame(width: 5, height: 5)
                    Text(timeString(from: timerMgr.secondsRemaining))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.orange)
                }
            } else if appState.isMicMuted {
                HStack(spacing: 4) {
                    Image(systemName: "mic.slash.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.red)
                    Text("Muted")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.red)
                }
            } else {
                Text(appState.miniStatusText)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(1)
            }

            Spacer()

            // Right Chevron Hint
            Image(systemName: "chevron.compact.down")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white.opacity(0.4))
                .padding(.trailing, 10)
        }
        .frame(width: appState.notchWidth, height: 34)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black)
                .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.8
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            NotchWindowController.shared.toggleExpand()
        }
    }

    // EXPANDED MODERN GLOSSY LIQUID GLASS HUD VIEW (WITH VERTICAL MENUBAR & MOTION FLAIR)
    private var expandedGlassNotchView: some View {
        VStack(spacing: 0) {
            // TOP NOTCH SAFE CLEARANCE (Physical camera notch sits safely in the empty middle!)
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(appState.currentTheme.primaryAccent)
                        .frame(width: 7, height: 7)
                    Text(appState.activeTab.rawValue)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                // Middle area intentionally kept clear for the MacBook camera notch!
                Spacer()

                HStack(spacing: 8) {
                    // Hardware Mic Status Pill
                    Button(action: {
                        appState.toggleMicMute()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: appState.isMicMuted ? "mic.slash.fill" : "mic.fill")
                                .font(.system(size: 9))
                            Text(appState.isMicMuted ? "Muted" : "Mic Live")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(appState.isMicMuted ? Color.red.opacity(0.25) : Color.white.opacity(0.08))
                        .foregroundColor(appState.isMicMuted ? .red : .white.opacity(0.8))
                        .cornerRadius(5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(appState.isMicMuted ? Color.red.opacity(0.5) : Color.white.opacity(0.12), lineWidth: 0.8)
                        )
                    }
                    .buttonStyle(.plain)

                    // License Status Pill / Unlock Button
                    Button(action: {
                        withAnimation {
                            licenseMgr.showActivationModal = true
                        }
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: licenseMgr.isLicensed && !licenseMgr.isTrialActive ? "checkmark.seal.fill" : "key.fill")
                                .font(.system(size: 9))
                            Text(licenseMgr.isLicensed && !licenseMgr.isTrialActive ? "VIP Lifetime" : (licenseMgr.isTrialActive ? "Trial (\(licenseMgr.trialDaysRemaining)d)" : "Unlock VIP"))
                                .font(.system(size: 10, weight: .bold))
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(licenseMgr.isLicensed && !licenseMgr.isTrialActive ? Color.green.opacity(0.18) : Color.purple.opacity(0.28))
                        .foregroundColor(licenseMgr.isLicensed && !licenseMgr.isTrialActive ? .green : .purple)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(licenseMgr.isLicensed && !licenseMgr.isTrialActive ? Color.green.opacity(0.4) : Color.purple.opacity(0.5), lineWidth: 0.8)
                        )
                    }
                    .buttonStyle(.plain)

                    Text("⌥+N")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))

                    Button(action: {
                        NotchWindowController.shared.collapse()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.55))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, appState.topNotchClearance)
            .padding(.bottom, 6)

            Divider()
                .background(Color.white.opacity(0.08))

            // MAIN TWO-COLUMN BODY: LEFT VERTICAL MENUBAR + RIGHT ACTIVE TOOL CONTENT
            HStack(spacing: 0) {
                // LEFT VERTICAL MENUBAR (Replaces horizontal bottom dock)
                verticalMenuBar
                    .frame(width: 68)
                    .background(Color.black.opacity(0.35))

                Divider()
                    .background(Color.white.opacity(0.08))

                // RIGHT MAIN ACTIVE TOOL CONTENT AREA
                ZStack {
                    switch appState.activeTab {
                    case .home:
                        HomeDashboardView()
                    case .nowPlaying:
                        NowPlayingView()
                    case .adhd:
                        ADHDToolsView()
                    case .tools:
                        SuperchargedToolsView()
                    case .aiUsage:
                        AIUsageTrackerView()
                    case .askAI:
                        AskAIAssistantView()
                    case .quickNotes:
                        QuickNotesView()
                    case .clipboard:
                        ClipboardHistoryView()
                    case .fileShelf:
                        FileShelfView()
                    case .cameraMirror:
                        CameraMirrorView()
                    case .teleprompter:
                        TeleprompterView()
                    case .settings:
                        SettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: appState.expandedWidth, height: appState.expandedHeight)
        .background(
            ZStack {
                // Liquid theme gradient
                appState.currentTheme.backgroundGradient
                    .opacity(appState.glassOpacity)

                // Ambient Radial Specular Glow Light
                RadialGradient(
                    colors: [appState.currentTheme.primaryAccent.opacity(0.18), Color.clear],
                    center: .top,
                    startRadius: 20,
                    endRadius: 400
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            // GLOWING EDGE FLAIR IN MOTION (Traveling glowing light stroke on hover/expansion)
            ZStack {
                if appState.showEdgeMotionFlair {
                    GlowingEdgeMotionFlair(
                        primaryColor: appState.currentTheme.primaryAccent,
                        secondaryColor: appState.currentTheme.secondaryAccent
                    )
                } else {
                    // Specular Liquid Glass Edge Highlight
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.38),
                                    Color.white.opacity(0.12),
                                    Color.white.opacity(0.04)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.2
                        )
                }
            }
        )
        .shadow(color: Color.black.opacity(0.7), radius: 36, x: 0, y: 18)
        .shadow(color: appState.currentTheme.primaryAccent.opacity(0.2), radius: 24, x: 0, y: 6)
    }

    // LEFT VERTICAL MENUBAR (Compact, native, icon + text tooltip)
    private var verticalMenuBar: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 4) {
                ForEach(NotchTab.allCases) { tab in
                    let isSelected = appState.activeTab == tab
                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            appState.activeTab = tab
                        }
                    }) {
                        VStack(spacing: 3) {
                            Image(systemName: tab.iconName)
                                .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? .white : .white.opacity(0.65))

                            Text(tab.rawValue)
                                .font(.system(size: 8.5, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? .white : .white.opacity(0.55))
                                .lineLimit(1)
                        }
                        .frame(width: 56, height: 44)
                        .background(
                            isSelected ?
                            LinearGradient(
                                colors: [
                                    appState.currentTheme.primaryAccent.opacity(0.85),
                                    appState.currentTheme.secondaryAccent.opacity(0.75)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.white.opacity(0.03)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isSelected ? appState.currentTheme.primaryAccent.opacity(0.6) : Color.clear, lineWidth: 1)
                        )
                        .shadow(color: isSelected ? appState.currentTheme.primaryAccent.opacity(0.4) : Color.clear, radius: 5, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .help(tab.rawValue)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
        }
    }

    private func timeString(from totalSeconds: Int) -> String {
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - GLOWING EDGE FLAIR IN MOTION (Animated Sweeping Border Light)
public struct GlowingEdgeMotionFlair: View {
    public let primaryColor: Color
    public let secondaryColor: Color

    @State private var phase: Double = 0.0

    public var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let angle = (time.truncatingRemainder(dividingBy: 4.0)) / 4.0 * 360.0

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            primaryColor.opacity(0.9),
                            secondaryColor.opacity(0.7),
                            Color.white.opacity(0.4),
                            Color.clear,
                            Color.clear,
                            Color.clear,
                            secondaryColor.opacity(0.3),
                            primaryColor.opacity(0.9)
                        ]),
                        center: .center,
                        startAngle: .degrees(angle),
                        endAngle: .degrees(angle + 360)
                    ),
                    lineWidth: 1.8
                )
                .overlay(
                    // Ambient diffuse outer glow beacon
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    primaryColor.opacity(0.5),
                                    secondaryColor.opacity(0.35),
                                    Color.clear,
                                    Color.clear,
                                    Color.clear,
                                    primaryColor.opacity(0.5)
                                ]),
                                center: .center,
                                startAngle: .degrees(angle),
                                endAngle: .degrees(angle + 360)
                            ),
                            lineWidth: 3.5
                        )
                        .blur(radius: 3.5)
                )
        }
    }
}
