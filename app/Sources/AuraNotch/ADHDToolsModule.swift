import SwiftUI
import AppKit

public struct ParkedThought: Identifiable {
    public let id = UUID()
    public let text: String
    public let time: String
}

public class ADHDManager: ObservableObject {
    public static let shared = ADHDManager()

    // 1. Next 1 Thing (Micro-Task Sprint)
    @Published public var currentTask: String = "Review PR and write summary"
    @Published public var isSprintActive: Bool = false
    @Published public var sprintMinutes: Int = 10
    @Published public var secondsRemaining: Int = 600
    @Published public var sprintsCompletedToday: Int = 3
    @Published public var encouragementText: String = "One task at a time. Ignore the rest of the world for 10 minutes."
    private var sprintTimer: Timer?

    // 2. Distraction Vault / Brain Dump
    @Published public var parkedThoughts: [ParkedThought] = [
        ParkedThought(text: "Check if flight prices dropped for conference", time: "14:22"),
        ParkedThought(text: "Order replacement mechanical keyboard switches", time: "16:05")
    ]
    @Published public var newThoughtInput: String = ""

    // 3. Box Breathing Grounding (4-4-4-4)
    @Published public var isBreathingActive: Bool = false
    @Published public var breathPhase: String = "Ready" // Inhale, Hold, Exhale, Rest
    @Published public var breathProgress: CGFloat = 0.6
    @Published public var breathSeconds: Int = 4
    private var breathTimer: Timer?
    private var breathCycleStep: Int = 0

    // 4. Dopamine Fidget Tapper
    @Published public var fidgetTaps: Int = 14
    @Published public var lastTapNotice: String? = nil

    private init() {}

    // --- Next 1 Thing Logic ---
    public func startSprint() {
        guard !currentTask.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSprintActive = true
        secondsRemaining = sprintMinutes * 60
        encouragementText = "Head down. Full flow state mode engaged."
        sprintTimer?.invalidate()
        sprintTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.secondsRemaining > 0 {
                self.secondsRemaining -= 1
            } else {
                self.completeSprint()
            }
        }
    }

    public func pauseSprint() {
        isSprintActive = false
        sprintTimer?.invalidate()
        sprintTimer = nil
        encouragementText = "Paused. Take a sip of water and jump right back in."
    }

    public func completeSprint() {
        pauseSprint()
        sprintsCompletedToday += 1
        encouragementText = "🎉 Victory! Sprint completed. Dopamine earned!"
        NSSound(named: "Hero")?.play()
    }

    public func snoozeSprint(extraMinutes: Int = 5) {
        secondsRemaining += extraMinutes * 60
        if !isSprintActive {
            startSprint()
        }
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

    // --- Box Breathing Logic (4-4-4-4) ---
    public func toggleBreathing() {
        isBreathingActive.toggle()
        if isBreathingActive {
            breathCycleStep = 0
            advanceBreathingStep()
            breathTimer?.invalidate()
            breathTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.tickBreathing()
            }
        } else {
            breathTimer?.invalidate()
            breathTimer = nil
            breathPhase = "Paused"
            breathProgress = 0.6
        }
    }

    private func tickBreathing() {
        if breathSeconds > 1 {
            breathSeconds -= 1
        } else {
            breathCycleStep = (breathCycleStep + 1) % 4
            advanceBreathingStep()
        }
    }

    private func advanceBreathingStep() {
        breathSeconds = 4
        switch breathCycleStep {
        case 0:
            breathPhase = "Inhale slowly..."
            breathProgress = 1.0
        case 1:
            breathPhase = "Hold gently..."
            breathProgress = 1.0
        case 2:
            breathPhase = "Exhale smoothly..."
            breathProgress = 0.4
        case 3:
            breathPhase = "Rest & clear mind..."
            breathProgress = 0.4
        default:
            break
        }
    }

    // --- Fidget Tapper Logic ---
    public func tapFidget() {
        fidgetTaps += 1
        NSSound(named: "Pop")?.play()
    }

    // --- Time Blindness Radar ---
    public var dayProgressPercent: Double {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let totalMinutes = (hour * 60) + currentMinute
        return min(max(Double(totalMinutes) / 1440.0, 0.0), 1.0)
    }

    public var workHorizonPercent: Double {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let startMinutes = 9 * 60 // 9:00 AM
        let endMinutes = 18 * 60  // 6:00 PM
        let currentMinutes = (hour * 60) + currentMinute

        if currentMinutes <= startMinutes { return 0.0 }
        if currentMinutes >= endMinutes { return 1.0 }
        return Double(currentMinutes - startMinutes) / Double(endMinutes - startMinutes)
    }
}

public struct ADHDToolsView: View {
    @ObservedObject var adhd = ADHDManager.shared
    @State private var activeTab = "Next 1 Thing"
    private let tabs = ["Next 1 Thing", "Distraction Vault", "Box Breathing", "Time Horizon & Fidget"]

    public var body: some View {
        VStack(spacing: 12) {
            // Sub-nav for ADHD toolkit
            Picker("", selection: $activeTab) {
                ForEach(tabs, id: \.self) { tab in
                    Text(tab).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 14)
            .padding(.top, 4)

            // Dynamic view selection
            if activeTab == "Next 1 Thing" {
                nextOneThingView
            } else if activeTab == "Distraction Vault" {
                distractionVaultView
            } else if activeTab == "Box Breathing" {
                boxBreathingView
            } else {
                timeHorizonAndFidgetView
            }
        }
        .padding(.bottom, 8)
    }

    // 1. NEXT 1 THING VIEW (ADHD Hyper-Focus Sprint)
    private var nextOneThingView: some View {
        VStack(spacing: 12) {
            // Big Focus Prompt
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("YOUR SOLE FOCUS RIGHT NOW:")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.purple)
                    Spacer()
                    Text("🔥 \(adhd.sprintsCompletedToday) Sprints Won Today")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.orange)
                }

                if adhd.isSprintActive {
                    Text(adhd.currentTask)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.purple.opacity(0.18))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.purple.opacity(0.5), lineWidth: 1)
                        )
                } else {
                    TextField("What is your single task? (e.g. Write customer reply)", text: $adhd.currentTask)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14, weight: .medium))
                        .padding(10)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)

            // Countdown Timer Display
            HStack(spacing: 20) {
                VStack(spacing: 2) {
                    Text(formatTime(adhd.secondsRemaining))
                        .font(.system(size: 38, weight: .bold, design: .monospaced))
                        .foregroundColor(adhd.isSprintActive ? .white : .white.opacity(0.6))

                    Text(adhd.encouragementText)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }

                // Preset sprint buttons
                if !adhd.isSprintActive {
                    HStack(spacing: 6) {
                        ForEach([5, 10, 15, 25], id: \.self) { mins in
                            Button(action: {
                                adhd.sprintMinutes = mins
                                adhd.secondsRemaining = mins * 60
                            }) {
                                Text("\(mins)m")
                                    .font(.system(size: 11, weight: adhd.sprintMinutes == mins ? .bold : .medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(adhd.sprintMinutes == mins ? Color.purple : Color.white.opacity(0.08))
                                    .cornerRadius(6)
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)

            // Action Buttons
            HStack(spacing: 12) {
                if !adhd.isSprintActive {
                    Button(action: { adhd.startSprint() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.fill")
                            Text("Start \(adhd.sprintMinutes)-Min Sprint")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: { adhd.completeSprint() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                            Text("Task Done! (Claim Win)")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .foregroundColor(.black)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    Button(action: { adhd.snoozeSprint(extraMinutes: 5) }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle")
                            Text("+5m")
                        }
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    Button(action: { adhd.pauseSprint() }) {
                        Text("Pause")
                            .font(.system(size: 11))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(.white.opacity(0.7))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                // ADHD Hack Tip
                Text("💡 Rule: If stuck, do just 60 seconds.")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.45))
            }
            .padding(.horizontal, 16)
        }
    }

    // 2. DISTRACTION VAULT (Park intrusive thoughts)
    private var distractionVaultView: some View {
        VStack(spacing: 10) {
            // Input field
            HStack(spacing: 8) {
                TextField("Park an intrusive thought so you don't derail...", text: $adhd.newThoughtInput, onCommit: {
                    adhd.parkThought()
                })
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .padding(8)
                .background(Color.white.opacity(0.08))
                .cornerRadius(8)
                .foregroundColor(.white)

                Button(action: { adhd.parkThought() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Park It")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.indigo)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)

            // Header & Actions
            HStack {
                Text("Parked Thoughts (\(adhd.parkedThoughts.count))")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .textCase(.uppercase)

                Spacer()

                if !adhd.parkedThoughts.isEmpty {
                    Button(action: { adhd.copyAllThoughts() }) {
                        Text("Copy All")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)

                    Button(action: { adhd.clearAllThoughts() }) {
                        Text("Clear All")
                            .font(.system(size: 10))
                            .foregroundColor(.red.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)

            // Scrollable list of parked items
            ScrollView {
                VStack(spacing: 6) {
                    if adhd.parkedThoughts.isEmpty {
                        VStack(spacing: 4) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.2))
                            Text("No parked distractions. Your mind is clear!")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .frame(maxWidth: .infinity, minHeight: 90)
                    } else {
                        ForEach(adhd.parkedThoughts) { item in
                            HStack {
                                Text(item.time)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.4))

                                Text(item.text)
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.9))
                                    .lineLimit(1)

                                Spacer()

                                Button(action: { adhd.deleteThought(id: item.id) }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 9))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(6)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(maxHeight: 120)
        }
    }

    // 3. BOX BREATHING VIEW (Grounding & Calming 4-4-4-4)
    private var boxBreathingView: some View {
        HStack(spacing: 24) {
            // Visual Breathing Bubble
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.cyan.opacity(0.4), Color.purple.opacity(0.2), Color.clear],
                            center: .center,
                            startRadius: 5,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                    .scaleEffect(adhd.breathProgress)
                    .animation(.easeInOut(duration: 4.0), value: adhd.breathProgress)

                Circle()
                    .stroke(Color.cyan.opacity(0.6), lineWidth: 2)
                    .frame(width: 80, height: 80)
                    .scaleEffect(adhd.breathProgress)
                    .animation(.easeInOut(duration: 4.0), value: adhd.breathProgress)

                Text("\(adhd.breathSeconds)s")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .frame(width: 110, height: 110)

            VStack(alignment: .leading, spacing: 8) {
                Text("Box Breathing (4-4-4-4)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)

                Text(adhd.isBreathingActive ? adhd.breathPhase : "Reset your nervous system when overwhelmed.")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.cyan)

                Text("Inhale 4s ➔ Hold 4s ➔ Exhale 4s ➔ Rest 4s\nClinically proven to lower heart rate & reset cognitive fatigue.")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))

                Button(action: { adhd.toggleBreathing() }) {
                    HStack(spacing: 5) {
                        Image(systemName: adhd.isBreathingActive ? "pause.fill" : "play.fill")
                        Text(adhd.isBreathingActive ? "Pause Exercise" : "Begin 4-4-4-4 Breathing")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(adhd.isBreathingActive ? Color.orange : Color.cyan)
                    .foregroundColor(.black)
                    .cornerRadius(7)
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    // 4. TIME HORIZON & FIDGET TAPPER
    private var timeHorizonAndFidgetView: some View {
        HStack(spacing: 20) {
            // Anti-Time Blindness Bar
            VStack(alignment: .leading, spacing: 8) {
                Text("Anti-Time Blindness Horizon")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .textCase(.uppercase)

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text("Day Progress (24h)")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Text("\(Int(adhd.dayProgressPercent * 100))%")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.purple)
                    }
                    ProgressView(value: adhd.dayProgressPercent)
                        .tint(.purple)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text("Work Horizon (9am - 6pm)")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Text("\(Int(adhd.workHorizonPercent * 100))%")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.orange)
                    }
                    ProgressView(value: adhd.workHorizonPercent)
                        .tint(.orange)
                }

                Text("ADHD brains perceive time as 'Now' or 'Not Now'. This bar anchors reality.")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(10)
            .background(Color.white.opacity(0.04))
            .cornerRadius(10)

            // Dopamine Fidget Tapper
            VStack(spacing: 8) {
                Text("Fidget Tap Sensor")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .textCase(.uppercase)

                Button(action: { adhd.tapFidget() }) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [Color.pink, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 54, height: 54)
                            .shadow(color: Color.pink.opacity(0.4), radius: 8)

                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)

                Text("\(adhd.fidgetTaps) Sensory Taps")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))

                Text("Click when feeling restless")
                    .font(.system(size: 8))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(10)
            .frame(width: 140)
            .background(Color.white.opacity(0.04))
            .cornerRadius(10)
        }
        .padding(.horizontal, 16)
    }

    private func formatTime(_ totalSeconds: Int) -> String {
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
