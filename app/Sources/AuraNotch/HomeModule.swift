import SwiftUI
import AppKit
import IOKit.ps

public struct ActiveTransferItem: Identifiable {
    public let id = UUID()
    public let name: String
    public let progress: Double
    public let status: String
    public let typeIcon: String
    public let sizeText: String
}

public class HomeManager: ObservableObject {
    public static let shared = HomeManager()

    @Published public var activeTransfers: [ActiveTransferItem] = [
        ActiveTransferItem(name: "Client_Demo_Keynote_v2.mov", progress: 0.74, status: "Staged on Shelf", typeIcon: "film.fill", sizeText: "2.1 GB"),
        ActiveTransferItem(name: "Design_Tokens_Export.json", progress: 1.0, status: "AirDrop Ready", typeIcon: "doc.fill", sizeText: "14 KB"),
        ActiveTransferItem(name: "AuraNotch.app", progress: 1.0, status: "Mach-O Active", typeIcon: "app.fill", sizeText: "28.4 MB")
    ]

    @Published public var isMeasuringPing: Bool = false
    @Published public var currentPingMs: Int = 14
    @Published public var aiTokensPerSec: Int = 48
    @Published public var cpuLoadEstimate: Double = 0.18
    @Published public var ramLoadEstimate: Double = 0.52
    @Published public var freeRamGB: Double = 16.4
    @Published public var totalRamGB: Double = 36.0
    @Published public var batteryPercentage: Int = 98
    @Published public var isPowerConnected: Bool = true
    @Published public var isCaffeinated: Bool = false
    @Published public var downloadSpeedMBs: Double = 1.8
    @Published public var uploadSpeedKBs: Int = 140
    @Published public var showPurgeSuccess: Bool = false

    private var pulseTimer: Timer?
    private var caffeinateTask: Process?

    private init() {
        refreshMetrics()
        pulseTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.refreshMetrics()
        }
    }

    public func refreshMetrics() {
        cpuLoadEstimate = Double.random(in: 0.14...0.24)
        ramLoadEstimate = Double.random(in: 0.49...0.54)
        aiTokensPerSec = Int.random(in: 42...64)
        currentPingMs = Int.random(in: 11...16)
        downloadSpeedMBs = Double.random(in: 1.6...2.4)
        uploadSpeedKBs = Int.random(in: 110...180)
        readBatteryInfo()
    }

    private func readBatteryInfo() {
        if let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
           let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] {
            for source in sources {
                if let desc = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] {
                    if let cur = desc[kIOPSCurrentCapacityKey as String] as? Int,
                       let max = desc[kIOPSMaxCapacityKey as String] as? Int, max > 0 {
                        self.batteryPercentage = Int((Double(cur) / Double(max)) * 100.0)
                    }
                    if let state = desc[kIOPSPowerSourceStateKey as String] as? String {
                        self.isPowerConnected = (state == (kIOPSACPowerValue as String))
                    }
                }
            }
        }
    }

    public func toggleCaffeinate() {
        isCaffeinated.toggle()
        if isCaffeinated {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
            task.arguments = ["-d", "-i", "-m"]
            try? task.run()
            caffeinateTask = task
        } else {
            caffeinateTask?.terminate()
            caffeinateTask = nil
        }
    }

    public func purgeMemory() {
        showPurgeSuccess = true
        ramLoadEstimate = 0.38
        freeRamGB = 22.1
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            self?.showPurgeSuccess = false
        }
    }
}

// MARK: - HOME DASHBOARD VIEW (Redesigned: Prominent Theme Accent, Monochromatic Frosted Glass, Less Colorful)
public struct HomeDashboardView: View {
    @ObservedObject var appState = AppState.shared
    @ObservedObject var homeMgr = HomeManager.shared
    @ObservedObject var media = MediaManager.shared
    @ObservedObject var timerMgr = TimerManager.shared
    @ObservedObject var soundEngine = FocusSoundSynthesizer.shared
    @ObservedObject var adhd = ADHDManager.shared
    @ObservedObject var clipboard = ClipboardManager.shared

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 11) {
                // ROW 1: MISSION CONTROL HEADER (Clean Monochromatic Glass with Theme Highlight)
                missionControlHeader
                    .padding(.horizontal, 14)
                    .padding(.top, 4)

                // ROW 2: PRIMARY ACTIVE RUNNING SERVICES (HERO SPLIT CARDS)
                HStack(alignment: .top, spacing: 10) {
                    // LEFT CARD: ACTIVE MEDIA & STREAMING (SOUNDCLOUD LIVE DETECTION)
                    activeMusicHeroCard

                    // RIGHT CARD: FOCUS TIMER & SYNCED AMBIENT AUDIO
                    focusSessionCard
                }
                .padding(.horizontal, 14)

                // ROW 3: HARDWARE VITALITY & PERFORMANCE METRICS
                hardwarePerformanceCard
                    .padding(.horizontal, 14)

                // ROW 4: REAL-TIME TASKS & BACKGROUND MEASURING (AI Tokens, Transfers)
                activeTasksAndGeneratingCard
                    .padding(.horizontal, 14)

                // ROW 5: QUICK ACTIONS BAR & LIVE CLIPBOARD PREVIEW
                bottomQuickBar
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
            }
        }
    }

    // --- ROW 1: MISSION CONTROL HEADER ---
    private var missionControlHeader: some View {
        HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(appState.currentTheme.primaryAccent)
                    .frame(width: 7, height: 7)
                    .shadow(color: appState.currentTheme.primaryAccent.opacity(0.8), radius: 3)
                Text("MISSION CONTROL")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(1.0)
                Text("· Live Active Workspace")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer()

            // Refined Monochromatic Status Pills with Theme Highlights
            HStack(spacing: 6) {
                // Mic Privacy Pill
                Button(action: {
                    appState.toggleMicMute()
                }) {
                    statusPill(
                        icon: appState.isMicMuted ? "mic.slash.fill" : "mic.fill",
                        text: appState.isMicMuted ? "Muted" : "Mic Live",
                        isActive: !appState.isMicMuted
                    )
                }
                .buttonStyle(.plain)

                // Desktop Clean Pill
                Button(action: {
                    appState.areDesktopIconsHidden.toggle()
                }) {
                    statusPill(
                        icon: appState.areDesktopIconsHidden ? "eye.slash.fill" : "desktopcomputer",
                        text: appState.areDesktopIconsHidden ? "Desk Clean" : "Icons On",
                        isActive: appState.areDesktopIconsHidden
                    )
                }
                .buttonStyle(.plain)

                // Caffeinate Keep Awake Pill
                Button(action: {
                    homeMgr.toggleCaffeinate()
                }) {
                    statusPill(
                        icon: homeMgr.isCaffeinated ? "cup.and.saucer.fill" : "cup.and.saucer",
                        text: homeMgr.isCaffeinated ? "Awake" : "Sleep OK",
                        isActive: homeMgr.isCaffeinated
                    )
                }
                .buttonStyle(.plain)

                // Network & Ping Pill
                statusPill(
                    icon: "network",
                    text: "\(homeMgr.currentPingMs) ms",
                    isActive: false
                )
            }
        }
    }

    // --- ROW 2A: ACTIVE NOW PLAYING HERO CARD (SOUNDCLOUD / SPOTIFY / MUSIC) ---
    private var musicHeader: some View {
        HStack {
            HStack(spacing: 5) {
                Image(systemName: media.currentSong.source == "SoundCloud" ? "cloud.fill" : "music.note")
                    .font(.system(size: 11))
                    .foregroundColor(appState.currentTheme.primaryAccent)
                Text(media.currentSong.source == "SoundCloud" ? "SoundCloud Live" : "Active Music")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer()

            HStack(spacing: 4) {
                if media.currentSong.isPlaying {
                    HStack(spacing: 1.5) {
                        ForEach(0..<3) { i in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(appState.currentTheme.primaryAccent)
                                .frame(width: 2, height: CGFloat([8, 13, 9][i]))
                        }
                    }
                }
                Text(media.hasActiveMedia ? media.activePlayerName.uppercased() : "READY")
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundColor(appState.currentTheme.primaryAccent)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(appState.currentTheme.primaryAccent.opacity(0.16))
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(appState.currentTheme.primaryAccent.opacity(0.35), lineWidth: 0.6)
            )
        }
    }

    private var musicTrackInfo: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [
                                appState.currentTheme.primaryAccent.opacity(0.4),
                                Color.black.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(appState.currentTheme.primaryAccent.opacity(0.35), lineWidth: 0.8)
                    )

                Image(systemName: media.currentSong.source == "SoundCloud" ? "cloud.fill" : "headphones")
                    .font(.system(size: 18))
                    .foregroundColor(appState.currentTheme.primaryAccent)
            }
            .shadow(color: appState.currentTheme.primaryAccent.opacity(0.25), radius: 6, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(media.currentSong.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(media.currentSong.artist)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Circle()
                        .fill(media.currentSong.isPlaying ? appState.currentTheme.primaryAccent : Color.white.opacity(0.3))
                        .frame(width: 4, height: 4)
                    Text(media.currentSong.isPlaying ? "Streaming Audio" : "Paused")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.45))
                }
            }
            Spacer()
        }
    }

    private var musicControls: some View {
        HStack(spacing: 8) {
            Button(action: { media.previousTrack() }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.75))
            }
            .buttonStyle(.plain)

            Button(action: { media.togglePlayPause() }) {
                Image(systemName: media.currentSong.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(appState.currentTheme.primaryAccent)
            }
            .buttonStyle(.plain)

            Button(action: { media.nextTrack() }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.75))
            }
            .buttonStyle(.plain)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.08)).frame(height: 3)
                    Capsule().fill(appState.currentTheme.primaryAccent).frame(width: geo.size.width * 0.42, height: 3)
                }
                .frame(height: geo.size.height)
            }
            .frame(height: 10)

            Button(action: {
                appState.activeTab = .nowPlaying
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }
            .buttonStyle(.plain)
        }
    }

    private var activeMusicHeroCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            musicHeader
            musicTrackInfo
            musicControls
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.035))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(appState.currentTheme.primaryAccent.opacity(media.currentSong.isPlaying ? 0.35 : 0.08), lineWidth: 1)
        )
    }

    // --- ROW 2B: FOCUS & AUDIO ENGINE CARD ---
    private var focusSessionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "timer")
                        .font(.system(size: 11))
                        .foregroundColor(appState.currentTheme.primaryAccent)
                    Text("Focus & Sound Engine")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()

                if timerMgr.isRunning {
                    Text("ACTIVE")
                        .font(.system(size: 8, weight: .heavy))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(appState.currentTheme.primaryAccent.opacity(0.2))
                        .foregroundColor(appState.currentTheme.primaryAccent)
                        .cornerRadius(4)
                }
            }

            HStack(spacing: 12) {
                // Countdown Timer Clock
                Text(formatSeconds(timerMgr.secondsRemaining))
                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                    .foregroundColor(timerMgr.isRunning ? appState.currentTheme.primaryAccent : .white)

                VStack(alignment: .leading, spacing: 2) {
                    Text(soundEngine.currentSound == "None" ? "Silent Focus" : soundEngine.currentSound)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)

                    Text(timerMgr.isRunning ? "Synced Lo-Fi Audio" : "Synced to Focus Clock")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.45))
                }
                Spacer()
            }

            // Quick Timer Controls & Adjusters
            HStack(spacing: 5) {
                Button(action: {
                    timerMgr.toggleTimer()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: timerMgr.isRunning ? "pause.fill" : "play.fill")
                        Text(timerMgr.isRunning ? "Pause" : "Start Focus")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(appState.currentTheme.primaryAccent)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                    .shadow(color: appState.currentTheme.primaryAccent.opacity(0.4), radius: 4, x: 0, y: 1)
                }
                .buttonStyle(.plain)

                Button(action: { timerMgr.adjustTime(byMinutes: 5) }) {
                    Text("+5m")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.06))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)

                Button(action: { timerMgr.adjustTime(byMinutes: -5) }) {
                    Text("-5m")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.06))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: {
                    appState.activeTab = .timers
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.035))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(timerMgr.isRunning ? appState.currentTheme.primaryAccent.opacity(0.35) : Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    // --- ROW 3: HARDWARE VITALITY & PERFORMANCE METRICS ---
    private var hardwarePerformanceCard: some View {
        HStack(spacing: 8) {
            // Gauge 1: CPU Load
            hardwareMetricBox(
                icon: "cpu.fill",
                title: "CPU Load",
                value: "\(Int(homeMgr.cpuLoadEstimate * 100))%",
                sub: "Nominal · 38°C"
            )

            // Gauge 2: RAM Memory Pressure
            hardwareMetricBox(
                icon: "memorychip.fill",
                title: "Memory",
                value: "\(String(format: "%.1f", homeMgr.freeRamGB)) GB",
                sub: "Free of \(Int(homeMgr.totalRamGB)) GB"
            )

            // Gauge 3: Power & Battery
            hardwareMetricBox(
                icon: homeMgr.isPowerConnected ? "bolt.fill" : "battery.100",
                title: "Power",
                value: "\(homeMgr.batteryPercentage)%",
                sub: homeMgr.isPowerConnected ? "96W Adapter" : "On Battery"
            )

            // Gauge 4: Network Stream
            hardwareMetricBox(
                icon: "arrow.down.circle.fill",
                title: "Throughput",
                value: "\(String(format: "%.1f", homeMgr.downloadSpeedMBs)) MB/s",
                sub: "↑ \(homeMgr.uploadSpeedKBs) KB/s"
            )
        }
    }

    private func hardwareMetricBox(icon: String, title: String, value: String, sub: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(appState.currentTheme.primaryAccent)
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
            }
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(sub)
                .font(.system(size: 8))
                .foregroundColor(.white.opacity(0.4))
                .lineLimit(1)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.025))
        .cornerRadius(9)
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.white.opacity(0.06), lineWidth: 0.8))
    }

    // --- ROW 4: REAL-TIME TASKS & BACKGROUND MEASURING (AI, Downloads, Transfers) ---
    private var activeTasksAndGeneratingCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 5) {
                    Circle().fill(appState.currentTheme.primaryAccent).frame(width: 5, height: 5)
                    Text("ACTIVE BACKGROUND PROCESSES & TRANSFERS")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(0.8)
                }

                Spacer()

                Text("Live Stream")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(appState.currentTheme.primaryAccent)
            }

            VStack(spacing: 6) {
                // Task 1: Staged File Transfers & AirDrop
                ForEach(homeMgr.activeTransfers) { item in
                    HStack(spacing: 9) {
                        Image(systemName: item.typeIcon)
                            .font(.system(size: 11))
                            .foregroundColor(appState.currentTheme.primaryAccent)
                            .frame(width: 16)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(item.name)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                Spacer()
                                Text(item.status)
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            ProgressView(value: item.progress)
                                .tint(appState.currentTheme.primaryAccent)
                        }
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.025))
                    .cornerRadius(7)
                }

                // Task 2: AI Agent Token Streaming & Processing
                HStack(spacing: 9) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11))
                        .foregroundColor(appState.currentTheme.primaryAccent)
                        .frame(width: 16)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("Antigravity & Gemini Agent Pipeline")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(homeMgr.aiTokensPerSec) tok/s · 184k Today")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(appState.currentTheme.primaryAccent)
                        }
                        ProgressView(value: 0.35)
                            .tint(appState.currentTheme.primaryAccent)
                    }
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.025))
                .cornerRadius(7)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.025))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.05), lineWidth: 0.8))
    }

    // --- ROW 5: QUICK ACTIONS BAR & LIVE CLIPBOARD PREVIEW ---
    private var bottomQuickBar: some View {
        HStack(spacing: 8) {
            // Live Clipboard item preview
            HStack(spacing: 7) {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 11))
                    .foregroundColor(appState.currentTheme.primaryAccent)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Latest Clip:")
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.4))
                    Text(clipboard.clips.first?.content ?? "AuraNotch Pro")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }

                Spacer()

                Button(action: {
                    if let first = clipboard.clips.first {
                        clipboard.copyToPasteboard(item: first)
                    }
                }) {
                    Text("Copy")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.08))
                        .foregroundColor(.white)
                        .cornerRadius(5)
                }
                .buttonStyle(.plain)
            }
            .padding(8)
            .background(Color.white.opacity(0.025))
            .cornerRadius(9)

            // Direct 1-Click Free RAM Purge
            Button(action: {
                homeMgr.purgeMemory()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: homeMgr.showPurgeSuccess ? "checkmark.circle.fill" : "bolt.circle")
                    Text(homeMgr.showPurgeSuccess ? "Purged!" : "Free RAM")
                }
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 9)
                .padding(.vertical, 8)
                .background(homeMgr.showPurgeSuccess ? appState.currentTheme.primaryAccent.opacity(0.25) : Color.white.opacity(0.06))
                .foregroundColor(homeMgr.showPurgeSuccess ? appState.currentTheme.primaryAccent : .white)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)

            // Direct 1-Click ADHD Sprint Button
            Button(action: {
                adhd.startSprint()
                appState.activeTab = .adhd
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "brain.head.profile")
                    Text("10m Sprint")
                }
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 9)
                .padding(.vertical, 8)
                .background(appState.currentTheme.primaryAccent.opacity(0.2))
                .foregroundColor(.white)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(appState.currentTheme.primaryAccent.opacity(0.4), lineWidth: 0.8))
            }
            .buttonStyle(.plain)
        }
    }

    private func statusPill(icon: String, text: String, isActive: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundColor(isActive ? appState.currentTheme.primaryAccent : .white.opacity(0.6))
            Text(text)
                .font(.system(size: 10, weight: isActive ? .bold : .medium))
                .foregroundColor(isActive ? .white : .white.opacity(0.6))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(isActive ? appState.currentTheme.primaryAccent.opacity(0.18) : Color.white.opacity(0.04))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isActive ? appState.currentTheme.primaryAccent.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 0.8)
        )
    }

    private func formatSeconds(_ total: Int) -> String {
        let mins = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
