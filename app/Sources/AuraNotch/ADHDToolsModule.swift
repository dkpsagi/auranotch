import SwiftUI
import AppKit

public struct ParkedThought: Identifiable, Codable {
    public var id = UUID()
    public var text: String
    public var time: String
}

public class ADHDManager: ObservableObject {
    public static let shared = ADHDManager()

    // 1. Title Text Area (Multi-Line Focus Objective)
    @Published public var currentTask: String = "Ship AuraNotch Pro 2.5 with unified ADHD & Focus Suite"
    @Published public var isSprintActive: Bool = false
    @Published public var sprintMinutes: Int = 25
    @Published public var secondsRemaining: Int = 25 * 60
    @Published public var sprintsCompletedToday: Int = 3
    @Published public var encouragementText: String = "One task at a time. Ignore the rest of the world for 25 minutes."
    private var sprintTimer: Timer?

    // 2. Audio Engine Controls (Live Synthesizer Integration)
    @Published public var isAudioEnabled: Bool = true
    @Published public var selectedSound: String = "Rain & Storm" // "Rain & Storm", "Binaural 40Hz Focus", "White Noise", "Forest Wind", "None"
    @Published public var audioVolume: Float = 0.50

    // 3. Distraction Vault / Brain Dump
    @Published public var parkedThoughts: [ParkedThought] = [
        ParkedThought(text: "Check if flight prices dropped for conference", time: "14:22"),
        ParkedThought(text: "Order replacement mechanical keyboard switches", time: "16:05")
    ]
    @Published public var newThoughtInput: String = ""

    // 4. Additional Power Features
    @Published public var zenDimmingEnabled: Bool = false
    @Published public var doNotDisturbEnabled: Bool = true

    public let soundTracks: [(name: String, icon: String, subtitle: String)] = [
        ("Rain & Storm", "cloud.rain.fill", "Brown noise rain"),
        ("Binaural 40Hz Focus", "headphones", "Gamma brainwaves"),
        ("White Noise", "waveform.path", "Broadband masking"),
        ("Forest Wind", "wind", "Pink noise gusts"),
        ("None", "speaker.slash", "Silent focus")
    ]

    private init() {}

    // --- Next 1 Thing Logic ---
    public func startSprint() {
        guard !currentTask.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSprintActive = true
        if secondsRemaining <= 0 {
            secondsRemaining = sprintMinutes * 60
        }
        encouragementText = "Head down. Full flow state mode engaged."

        // Start live audio synthesizer if audio is toggled ON
        if isAudioEnabled && selectedSound != "None" {
            FocusSoundSynthesizer.shared.updateVolume(audioVolume)
            FocusSoundSynthesizer.shared.play(sound: selectedSound)
        }

        AppState.shared.isTimerRunning = true
        AppState.shared.activeTimerSecondsRemaining = secondsRemaining

        sprintTimer?.invalidate()
        sprintTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.secondsRemaining > 0 {
                self.secondsRemaining -= 1
                AppState.shared.activeTimerSecondsRemaining = self.secondsRemaining
            } else {
                self.completeSprint()
            }
        }
    }

    public func pauseSprint() {
        isSprintActive = false
        sprintTimer?.invalidate()
        sprintTimer = nil
        encouragementText = "Paused. Take a breath and jump back in when ready."
        FocusSoundSynthesizer.shared.stop()
        AppState.shared.isTimerRunning = false
    }

    public func completeSprint() {
        pauseSprint()
        sprintsCompletedToday += 1
        secondsRemaining = sprintMinutes * 60
        encouragementText = "🎉 Victory! Sprint completed. Dopamine earned!"
        NSSound(named: "Hero")?.play()
    }

    public func adjustTime(byMinutes mins: Int) {
        let delta = mins * 60
        let newSeconds = secondsRemaining + delta
        if newSeconds >= 60 {
            secondsRemaining = newSeconds
            sprintMinutes = max(1, secondsRemaining / 60)
            AppState.shared.activeTimerSecondsRemaining = secondsRemaining
        }
    }

    public func setPreset(mins: Int) {
        sprintMinutes = mins
        secondsRemaining = mins * 60
        AppState.shared.activeTimerSecondsRemaining = secondsRemaining
        encouragementText = "Ready for a \(mins)m sprint. Click Start to enter flow state."
    }

    public func resetSprint() {
        pauseSprint()
        secondsRemaining = sprintMinutes * 60
        AppState.shared.activeTimerSecondsRemaining = secondsRemaining
        encouragementText = "Timer reset to \(sprintMinutes)m."
    }

    public func snoozeSprint(extraMinutes: Int = 5) {
        secondsRemaining += extraMinutes * 60
        AppState.shared.activeTimerSecondsRemaining = secondsRemaining
        if !isSprintActive {
            startSprint()
        }
    }

    // --- Audio Control Methods ---
    public func toggleAudio() {
        isAudioEnabled.toggle()
        if isAudioEnabled {
            if isSprintActive && selectedSound != "None" {
                FocusSoundSynthesizer.shared.updateVolume(audioVolume)
                FocusSoundSynthesizer.shared.play(sound: selectedSound)
            }
        } else {
            FocusSoundSynthesizer.shared.stop()
        }
    }

    public func selectSoundTrack(_ track: String) {
        selectedSound = track
        if isAudioEnabled && isSprintActive {
            FocusSoundSynthesizer.shared.updateVolume(audioVolume)
            FocusSoundSynthesizer.shared.play(sound: track)
        }
    }

    public func setVolume(_ vol: Float) {
        audioVolume = vol
        FocusSoundSynthesizer.shared.updateVolume(vol)
    }

    // --- Distraction Vault Logic ---
    public func parkThought() {
        let trimmed = newThoughtInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let item = ParkedThought(text: trimmed, time: formatter.string(from: Date()))
        parkedThoughts.insert(item, at: 0)
        newThoughtInput = ""
        NSSound(named: "Tink")?.play()
    }

    public func deleteThought(id: UUID) {
        parkedThoughts.removeAll { $0.id == id }
    }

    public func clearAllThoughts() {
        parkedThoughts.removeAll()
    }

    public func copyAllThoughts() {
        let combined = parkedThoughts.map { "• [\($0.time)] \($0.text)" }.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(combined, forType: .string)
    }
}

// MARK: - UNIFIED ADHD & FOCUS VIEW
public struct ADHDToolsView: View {
    @ObservedObject var appState = AppState.shared
    @ObservedObject var adhd = ADHDManager.shared

    public init() {}

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                // 1. TOP HEADER & STREAKS
                headerBar

                // 2. TITLE TEXT AREA (Single Focus Objective)
                taskTitleSection

                // 3. PRECISION TIMER & SPRINT CONTROLS
                timerControlsSection

                // 4. MUSIC & AMBIENT AUDIO ENGINE (ON/OFF)
                audioEngineSection

                // 5. DISTRACTION VAULT (Brain Dump)
                distractionVaultSection
            }
            .padding(14)
        }
    }

    // --- 1. Header Bar ---
    private var headerBar: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 13))
                    .foregroundColor(appState.currentTheme.primaryAccent)
                Text("ADHD & FOCUS SUITE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(0.8)
            }

            Spacer()

            // Zen Mode Dimmer Toggle
            Button(action: {
                adhd.zenDimmingEnabled.toggle()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: adhd.zenDimmingEnabled ? "moon.fill" : "moon")
                        .font(.system(size: 10))
                    Text(adhd.zenDimmingEnabled ? "Zen Light Active" : "Zen Light")
                        .font(.system(size: 10, weight: .medium))
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(adhd.zenDimmingEnabled ? appState.currentTheme.primaryAccent.opacity(0.3) : Color.white.opacity(0.06))
                .foregroundColor(adhd.zenDimmingEnabled ? .white : .white.opacity(0.7))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)

            // Dopamine Streak Counter
            HStack(spacing: 4) {
                Text("🔥")
                Text("\(adhd.sprintsCompletedToday) Sprints Won Today")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.orange)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.orange.opacity(0.15))
            .cornerRadius(6)
        }
    }

    // --- 2. Title Text Area Section ---
    private var taskTitleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("SINGLE ACTIVE FOCUS OBJECTIVE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.45))
                    .tracking(0.6)

                Spacer()

                if !adhd.currentTask.isEmpty {
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(adhd.currentTask, forType: .string)
                    }) {
                        Text("Copy")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        adhd.currentTask = ""
                    }) {
                        Text("Clear")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Text Field / Text Area for Focus Goal
            ZStack(alignment: .topLeading) {
                if adhd.currentTask.isEmpty {
                    Text("What single outcome are you conquering right now?")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.3))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 9)
                }

                TextField("", text: $adhd.currentTask)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 9)
            }
            .background(Color.white.opacity(adhd.isSprintActive ? 0.08 : 0.04))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        adhd.isSprintActive ?
                        appState.currentTheme.primaryAccent.opacity(0.7) :
                        Color.white.opacity(0.1),
                        lineWidth: adhd.isSprintActive ? 1.4 : 0.8
                    )
            )
            .shadow(color: adhd.isSprintActive ? appState.currentTheme.primaryAccent.opacity(0.25) : Color.clear, radius: 8)
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 0.8))
    }

    // --- 3. Precision Timer Controls Section ---
    private var timerControlsSection: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 18) {
                // Giant Digital Clock
                VStack(alignment: .leading, spacing: 2) {
                    Text(formatTime(adhd.secondsRemaining))
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(adhd.isSprintActive ? appState.currentTheme.primaryAccent : .white)

                    Text(adhd.encouragementText)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.55))
                        .lineLimit(1)
                }

                Spacer()

                // Sprint Presets
                HStack(spacing: 5) {
                    ForEach([15, 25, 45, 60], id: \.self) { mins in
                        Button(action: {
                            adhd.setPreset(mins: mins)
                        }) {
                            Text("\(mins)m")
                                .font(.system(size: 10, weight: adhd.sprintMinutes == mins ? .bold : .medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(
                                    adhd.sprintMinutes == mins ?
                                    appState.currentTheme.primaryAccent :
                                    Color.white.opacity(0.06)
                                )
                                .cornerRadius(6)
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Action Buttons Row
            HStack(spacing: 8) {
                if !adhd.isSprintActive {
                    Button(action: { adhd.startSprint() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                            Text("Start \(adhd.sprintMinutes)m Sprint")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [appState.currentTheme.primaryAccent, appState.currentTheme.secondaryAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .shadow(color: appState.currentTheme.primaryAccent.opacity(0.4), radius: 6, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: { adhd.pauseSprint() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "pause.fill")
                            Text("Pause")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.14))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    Button(action: { adhd.completeSprint() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Complete & Win")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .shadow(color: Color.green.opacity(0.4), radius: 6, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)

                    Button(action: { adhd.snoozeSprint(extraMinutes: 5) }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("5m Snooze")
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.08))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }

                // Adjust Time +/- Buttons
                Button(action: { adhd.adjustTime(byMinutes: -5) }) {
                    Text("-5m")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.06))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Button(action: { adhd.adjustTime(byMinutes: 5) }) {
                    Text("+5m")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.06))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)

                // Reset Button
                Button(action: { adhd.resetSprint() }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.06))
                        .foregroundColor(.white.opacity(0.7))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .help("Reset Timer")

                Spacer()
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.035))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 0.8))
    }

    // --- 4. Music & Focus Sound Engine Section ---
    private var audioEngineSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with Music ON / OFF switch
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "headphones")
                        .font(.system(size: 11))
                        .foregroundColor(appState.currentTheme.primaryAccent)
                    Text("FOCUS AUDIO & MUSIC ENGINE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.45))
                        .tracking(0.6)
                }

                Spacer()

                // Music ON / OFF Toggle
                Button(action: {
                    adhd.toggleAudio()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: adhd.isAudioEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.system(size: 10))
                        Text(adhd.isAudioEnabled ? "Music ON" : "Music OFF")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        adhd.isAudioEnabled ?
                        appState.currentTheme.primaryAccent.opacity(0.25) :
                        Color.white.opacity(0.06)
                    )
                    .foregroundColor(adhd.isAudioEnabled ? appState.currentTheme.primaryAccent : .white.opacity(0.5))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(adhd.isAudioEnabled ? appState.currentTheme.primaryAccent.opacity(0.5) : Color.clear, lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
            }

            // Sound Track Selector Cards
            HStack(spacing: 6) {
                ForEach(adhd.soundTracks, id: \.name) { track in
                    let isSelected = adhd.selectedSound == track.name
                    Button(action: {
                        adhd.selectSoundTrack(track.name)
                    }) {
                        VStack(spacing: 3) {
                            Image(systemName: track.icon)
                                .font(.system(size: 12))
                                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                            Text(track.name)
                                .font(.system(size: 8.5, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            isSelected ?
                            appState.currentTheme.primaryAccent.opacity(0.35) :
                            Color.white.opacity(0.035)
                        )
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? appState.currentTheme.primaryAccent.opacity(0.6) : Color.white.opacity(0.05), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Volume Slider & Sync Status
            HStack(spacing: 10) {
                Image(systemName: "speaker.wave.1.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))

                Slider(value: Binding(
                    get: { Double(adhd.audioVolume) },
                    set: { adhd.setVolume(Float($0)) }
                ), in: 0...1)
                .accentColor(appState.currentTheme.primaryAccent)
                .frame(width: 120)

                Text("\(Int(adhd.audioVolume * 100))%")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(adhd.isSprintActive && adhd.isAudioEnabled ? Color.green : Color.white.opacity(0.3))
                        .frame(width: 5, height: 5)
                    Text(adhd.isSprintActive ? "Audio Synced & Active" : "Audio Synced to Clock")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.45))
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 0.8))
    }

    // --- 5. Distraction Vault (Brain Dump) Section ---
    private var distractionVaultSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "tray.and.arrow.down.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                    Text("BRAIN DUMP & DISTRACTION VAULT")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.45))
                        .tracking(0.6)
                }

                Spacer()

                if !adhd.parkedThoughts.isEmpty {
                    Button(action: { adhd.copyAllThoughts() }) {
                        Text("Copy All")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(appState.currentTheme.primaryAccent)
                    }
                    .buttonStyle(.plain)

                    Button(action: { adhd.clearAllThoughts() }) {
                        Text("Clear")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Input to park thought
            HStack(spacing: 8) {
                TextField("Park intrusive thoughts here to keep focus...", text: $adhd.newThoughtInput, onCommit: {
                    adhd.parkThought()
                })
                .textFieldStyle(.plain)
                .font(.system(size: 11))
                .padding(8)
                .background(Color.black.opacity(0.4))
                .cornerRadius(7)
                .foregroundColor(.white)
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.white.opacity(0.08), lineWidth: 0.8))

                Button(action: { adhd.parkThought() }) {
                    Text("Park")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(appState.currentTheme.primaryAccent.opacity(0.25))
                        .foregroundColor(.white)
                        .cornerRadius(7)
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(appState.currentTheme.primaryAccent.opacity(0.5), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
            }

            // List of parked thoughts
            if adhd.parkedThoughts.isEmpty {
                Text("No intrusive thoughts parked. Pure focus zone.")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.vertical, 4)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 4) {
                        ForEach(adhd.parkedThoughts) { thought in
                            HStack {
                                Text("[\(thought.time)]")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(appState.currentTheme.primaryAccent)
                                Text(thought.text)
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.85))
                                    .lineLimit(1)
                                Spacer()
                                Button(action: { adhd.deleteThought(id: thought.id) }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 9))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.white.opacity(0.02))
                            .cornerRadius(6)
                        }
                    }
                }
                .frame(maxHeight: 90)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.025))
        .cornerRadius(10)
    }

    private func formatTime(_ totalSeconds: Int) -> String {
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
