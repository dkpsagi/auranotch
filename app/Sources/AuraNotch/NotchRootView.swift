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

            // Onboarding & License Key Activation Modal (Screenshots 1 & 2)
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
                Text("AuraNotch")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
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

    // EXPANDED MODERN GLOSSY LIQUID GLASS HUD VIEW
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

                HStack(spacing: 10) {
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

                    Text("⌥+N to toggle")
                        .font(.system(size: 10))
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
            .padding(.horizontal, 18)
            .padding(.top, appState.topNotchClearance) // User-customizable notch height clearance
            .padding(.bottom, 6)

            Divider()
                .background(Color.white.opacity(0.08))

            // MAIN ACTIVE TOOL CONTENT AREA
            ZStack {
                switch appState.activeTab {
                case .home:
                    HomeDashboardView()
                case .adhd:
                    ADHDToolsView()
                case .tools:
                    SuperchargedToolsView()
                case .clipboard:
                    ClipboardHistoryView()
                case .nowPlaying:
                    NowPlayingView()
                case .aiUsage:
                    AIUsageTrackerView()
                case .askAI:
                    AskAIAssistantView()
                case .teleprompter:
                    TeleprompterView()
                case .timers:
                    TimersPomodoroView()
                case .fileShelf:
                    FileShelfView()
                case .sales:
                    SalesTrackerView()
                case .cameraMirror:
                    CameraMirrorView()
                case .quickNotes:
                    QuickNotesView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()
                .background(Color.white.opacity(0.08))

            // CATEGORY FILTER PILLS (Instant Fast Navigation)
            HStack(spacing: 6) {
                ForEach(NotchTabCategory.allCases) { cat in
                    let isCatSelected = appState.selectedTabCategory == cat
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            appState.selectedTabCategory = cat
                            if cat != .all && appState.activeTab.category != cat {
                                if let firstTab = NotchTab.allCases.first(where: { $0.category == cat }) {
                                    appState.activeTab = firstTab
                                }
                            }
                        }
                    }) {
                        Text(cat.rawValue)
                            .font(.system(size: 10, weight: isCatSelected ? .bold : .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(isCatSelected ? appState.currentTheme.primaryAccent.opacity(0.25) : Color.white.opacity(0.04))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(isCatSelected ? appState.currentTheme.primaryAccent.opacity(0.5) : Color.clear, lineWidth: 1)
                            )
                            .foregroundColor(isCatSelected ? .white : .white.opacity(0.55))
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 6)
            .padding(.bottom, 2)
            .background(Color.black.opacity(0.2))

            // BOTTOM TOOL NAVIGATION DOCK (NON-SCROLLABLE: Icon only by default, expands to icon + text when selected)
            let visibleTabs = appState.selectedTabCategory == .all ?
                NotchTab.allCases :
                NotchTab.allCases.filter { $0.category == appState.selectedTabCategory }

            HStack(spacing: 5) {
                Spacer()
                ForEach(visibleTabs) { tab in
                    let isSelected = appState.activeTab == tab
                    Button(action: {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            appState.activeTab = tab
                        }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: tab.iconName)
                                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                            if isSelected {
                                Text(tab.rawValue)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .lineLimit(1)
                                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                            }
                        }
                        .padding(.horizontal, isSelected ? 12 : 8)
                        .padding(.vertical, 7)
                        .frame(height: 32)
                        .background(
                            isSelected ?
                            LinearGradient(
                                colors: [appState.currentTheme.primaryAccent, appState.currentTheme.secondaryAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.white.opacity(0.06)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(9)
                        .foregroundColor(isSelected ? .white : .white.opacity(0.65))
                        .shadow(color: isSelected ? appState.currentTheme.primaryAccent.opacity(0.45) : Color.clear, radius: 6, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .help(tab.rawValue)
                }
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.35))
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
        )
        .shadow(color: Color.black.opacity(0.7), radius: 36, x: 0, y: 18)
        .shadow(color: appState.currentTheme.primaryAccent.opacity(0.12), radius: 24, x: 0, y: 6)
    }

    private func timeString(from totalSeconds: Int) -> String {
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
