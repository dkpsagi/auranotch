import SwiftUI

public struct NotchRootView: View {
    @ObservedObject var appState = AppState.shared
    @ObservedObject var media = MediaManager.shared
    @ObservedObject var timerMgr = TimerManager.shared
    @ObservedObject var soundEngine = FocusSoundSynthesizer.shared
    @ObservedObject var licenseMgr = LicenseManager.shared
    @ObservedObject var adhd = ADHDManager.shared
    @State private var showMusicPopover: Bool = false

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

    // MARK: - REVERSE-ENGINEERED NOTCHFLOW HARDWARE BAR (Black, Safety Orange & White)
    private var closedPillView: some View {
        HStack(spacing: 8) {
            // 1. Circular Stop Button (■)
            Button(action: {
                adhd.resetSprint()
                NSSound(named: "Pop")?.play()
            }) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.12, green: 0.12, blue: 0.14))
                        .frame(width: 24, height: 24)
                        .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.8))
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color.white)
                        .frame(width: 7, height: 7)
                }
            }
            .buttonStyle(.plain)
            .help("Stop / Reset Timer")

            // 2. Vibrant Orange Play / Pause Button (▶ / ⏸)
            Button(action: {
                if adhd.isSprintActive {
                    adhd.pauseSprint()
                } else {
                    adhd.startSprint()
                }
                NSSound(named: "Tink")?.play()
            }) {
                ZStack {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.38, blue: 0.05)) // Electric Safety Orange
                        .frame(width: 26, height: 26)
                        .shadow(color: Color(red: 1.0, green: 0.38, blue: 0.05).opacity(0.45), radius: 5, x: 0, y: 1)
                    Image(systemName: adhd.isSprintActive ? "pause.fill" : "play.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: adhd.isSprintActive ? 0 : 0.8)
                }
            }
            .buttonStyle(.plain)
            .help(adhd.isSprintActive ? "Pause Flow" : "Start Flow")

            // 3. Digital Segment Timer with Vertical Orange Sweep Line (NotchFlow Signature)
            GeometryReader { geo in
                let totalSecs = max(adhd.sprintMinutes * 60, 1)
                let elapsed = Double(totalSecs - adhd.secondsRemaining)
                let progress = min(max(elapsed / Double(totalSecs), 0.0), 1.0)
                let sweepX = geo.size.width * CGFloat(progress)

                ZStack(alignment: .leading) {
                    // Inset dark track
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(red: 0.06, green: 0.06, blue: 0.07))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                        )

                    // Subtle orange fill behind progress sweep
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.38, blue: 0.05).opacity(0.18), Color.clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(sweepX, 0))

                    // Vertical Orange Progress Cursor Line
                    Rectangle()
                        .fill(Color(red: 1.0, green: 0.38, blue: 0.05))
                        .frame(width: 2, height: geo.size.height - 4)
                        .offset(x: max(sweepX - 1, 2))
                        .shadow(color: Color(red: 1.0, green: 0.38, blue: 0.05).opacity(0.85), radius: 2)

                    // Countdown text centered in crisp mono white
                    HStack {
                        Spacer()
                        Text(timeString(from: adhd.secondsRemaining))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .tracking(1.0)
                        Spacer()
                    }
                }
            }
            .frame(width: 95, height: 24)

            // 4. Coffee Break Toggle Button (☕)
            Button(action: {
                adhd.toggleCoffeeBreak()
                NSSound(named: "Pop")?.play()
            }) {
                ZStack {
                    Circle()
                        .fill(adhd.isBreakMode ? Color(red: 1.0, green: 0.38, blue: 0.05).opacity(0.28) : Color(red: 0.12, green: 0.12, blue: 0.14))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(adhd.isBreakMode ? Color(red: 1.0, green: 0.38, blue: 0.05) : Color.white.opacity(0.12), lineWidth: 0.8)
                        )
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 10))
                        .foregroundColor(adhd.isBreakMode ? Color(red: 1.0, green: 0.38, blue: 0.05) : .white)
                }
            }
            .buttonStyle(.plain)
            .help(adhd.isBreakMode ? "Coffee Break Active (5m)" : "Take a Coffee Break (5m)")

            // 5. Album Artwork / Music Popover Trigger
            Button(action: {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                    showMusicPopover.toggle()
                }
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color(red: 0.15, green: 0.15, blue: 0.18))
                        .frame(width: 24, height: 24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                        )
                    Image(systemName: media.hasActiveMedia && media.currentSong.isPlaying ? "waveform" : "music.note")
                        .font(.system(size: 10))
                        .foregroundColor(media.hasActiveMedia && media.currentSong.isPlaying ? Color(red: 1.0, green: 0.38, blue: 0.05) : .white.opacity(0.8))
                }
            }
            .buttonStyle(.plain)
            .help("Now Playing Music & Volume Dial")
            .popover(isPresented: $showMusicPopover) {
                NotchFlowMusicPopoverView()
            }

            // 6. Menu / Expand Trigger Button (≡)
            Button(action: {
                NotchWindowController.shared.toggleExpand()
            }) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.12, green: 0.12, blue: 0.14))
                        .frame(width: 24, height: 24)
                        .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.8))
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .help("Expand AuraNotch 27-Tool Mission Control")
        }
        .padding(.horizontal, 10)
        .frame(width: appState.notchWidth, height: 34)
        .background(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(Color.black)
                .shadow(color: Color.black.opacity(0.75), radius: 10, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.20), Color.white.opacity(0.04)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.8
                )
        )
        .contentShape(Rectangle())
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

// MARK: - NOTCHFLOW TACTILE MUSIC POPOVER & ROTARY VOLUME DIAL
public struct NotchFlowMusicPopoverView: View {
    @ObservedObject var media = MediaManager.shared
    @ObservedObject var adhd = ADHDManager.shared
    @State private var isShuffleActive: Bool = false

    private var playerBadge: String {
        if media.hasActiveMedia {
            return media.activePlayerName.uppercased()
        }
        return "FOCUS SOUNDSCAPES"
    }

    private var displayTitle: String {
        if media.hasActiveMedia && !media.currentSong.title.isEmpty {
            return media.currentSong.title
        }
        return "NotchFlow Focus Stream"
    }

    private var displayArtist: String {
        if media.hasActiveMedia && !media.currentSong.artist.isEmpty {
            return media.currentSong.artist
        }
        return adhd.selectedSound
    }

    private var isCurrentlyPlaying: Bool {
        if media.hasActiveMedia {
            return media.currentSong.isPlaying
        }
        return adhd.isAudioEnabled
    }

    public var body: some View {
        VStack(spacing: 14) {
            // Header / App Badge
            HStack {
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.38, blue: 0.05))
                        .frame(width: 6, height: 6)
                    Text(playerBadge)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                )

                Spacer()

                Text("AuraNotch Sound")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            }

            // Track Artwork & Metadata
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.20, green: 0.20, blue: 0.24), Color(red: 0.10, green: 0.10, blue: 0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 54, height: 54)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                        )
                        .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 3)

                    Image(systemName: isCurrentlyPlaying ? "waveform" : "headphones")
                        .font(.system(size: 22))
                        .foregroundColor(Color(red: 1.0, green: 0.38, blue: 0.05))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(displayTitle)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(displayArtist)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)

                    // Audio Stream status
                    HStack(spacing: 4) {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .font(.system(size: 9))
                            .foregroundColor(Color(red: 1.0, green: 0.38, blue: 0.05))
                        Text(media.hasActiveMedia ? "System Synced" : "ADHD Audio Engine")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.top, 2)
                }
                Spacer()
            }

            // Player Transport Controls
            HStack(spacing: 18) {
                Button(action: {
                    isShuffleActive.toggle()
                }) {
                    Image(systemName: "shuffle")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(isShuffleActive ? Color(red: 1.0, green: 0.38, blue: 0.05) : .white.opacity(0.5))
                }
                .buttonStyle(.plain)

                Button(action: {
                    media.skipPrev()
                }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.85))
                }
                .buttonStyle(.plain)

                // NotchFlow Signature Orange Play Button
                Button(action: {
                    if media.hasActiveMedia {
                        media.togglePlayPause()
                    } else {
                        adhd.toggleAudio()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 1.0, green: 0.38, blue: 0.05))
                            .frame(width: 38, height: 38)
                            .shadow(color: Color(red: 1.0, green: 0.38, blue: 0.05).opacity(0.4), radius: 6, x: 0, y: 2)

                        Image(systemName: isCurrentlyPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)

                Button(action: {
                    media.skipNext()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.85))
                }
                .buttonStyle(.plain)

                Button(action: {
                    adhd.toggleAudio()
                }) {
                    Image(systemName: "waveform.badge.magnifyingglass")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(adhd.isAudioEnabled ? Color(red: 1.0, green: 0.38, blue: 0.05) : .white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)

            Divider()
                .background(Color.white.opacity(0.08))

            // Tactile Rotary Volume Dial Knob (NotchFlow Signature)
            TactileRotaryVolumeKnob(volume: Binding(
                get: { media.volume },
                set: { newVol in
                    media.volume = max(0.0, min(1.0, newVol))
                }
            ))
            .padding(.vertical, 2)
        }
        .padding(16)
        .frame(width: 270)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.07, green: 0.07, blue: 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(0.8), radius: 18, x: 0, y: 8)
        )
    }
}

// MARK: - TACTILE ROTARY VOLUME KNOB (12-Dot Radial Ring & Center Marker)
public struct TactileRotaryVolumeKnob: View {
    @Binding public var volume: Double

    // Arc range from -120 deg to +120 deg (total 240 deg sweep)
    private let totalDots = 12
    private let sweepAngle: Double = 240.0
    private let startAngle: Double = -120.0

    @State private var dragStartVolume: Double = 0.0

    public var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Outer ring of 12 tactile status dots
                ForEach(0..<totalDots, id: \.self) { index in
                    let fraction = Double(index) / Double(totalDots - 1)
                    let angleDeg = startAngle + (fraction * sweepAngle)
                    let angleRad = (angleDeg - 90.0) * .pi / 180.0
                    let radius: CGFloat = 32.0
                    let x = cos(angleRad) * radius
                    let y = sin(angleRad) * radius
                    let isActive = fraction <= volume

                    Circle()
                        .fill(isActive ? Color(red: 1.0, green: 0.38, blue: 0.05) : Color.white.opacity(0.15))
                        .frame(width: 4, height: 4)
                        .offset(x: x, y: y)
                }

                // Center dark metallic dial knob
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(red: 0.22, green: 0.22, blue: 0.25), Color(red: 0.10, green: 0.10, blue: 0.12)],
                            center: .center,
                            startRadius: 2,
                            endRadius: 24
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                    )
                    .shadow(color: Color.black.opacity(0.5), radius: 4, x: 0, y: 2)
                    .overlay(
                        // Radial orange tick indicator pointing towards the active angle
                        Rectangle()
                            .fill(Color(red: 1.0, green: 0.38, blue: 0.05))
                            .frame(width: 2.5, height: 9)
                            .offset(y: -14)
                            .rotationEffect(.degrees(startAngle + (volume * sweepAngle)))
                    )
                    .gesture(
                        DragGesture(minimumDistance: 1)
                            .onChanged { value in
                                let delta = -Double(value.translation.height) / 120.0
                                let updated = max(0.0, min(1.0, dragStartVolume + delta))
                                volume = updated
                            }
                            .onEnded { _ in
                                dragStartVolume = volume
                            }
                    )
                    .onAppear {
                        dragStartVolume = volume
                    }
            }
            .frame(width: 76, height: 76)

            // Volume Label & Level
            HStack(spacing: 4) {
                Text("ROTARY VOLUME")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.45))
                    .tracking(1)

                Spacer()

                Text("\(Int(volume * 100))%")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 1.0, green: 0.38, blue: 0.05))
            }
            .padding(.horizontal, 10)
        }
    }
}
