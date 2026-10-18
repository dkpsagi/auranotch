import SwiftUI
import AppKit

public struct ParkedThought: Identifiable, Codable {
    public var id = UUID()
    public var text: String
    public var time: String
}

public class ADHDManager: ObservableObject {
    public static let shared = ADHDManager()

    // Next 1 Thing (Micro-Task Sprint)
    @Published public var currentTask: String = "Review PR and write summary"
    @Published public var isSprintActive: Bool = false
    @Published public var sprintMinutes: Int = 15
    @Published public var secondsRemaining: Int = 900
    @Published public var sprintsCompletedToday: Int = 3
    @Published public var encouragementText: String = "One task at a time. Ignore the rest of the world for 15 minutes."
    private var sprintTimer: Timer?

    // Distraction Vault / Brain Dump
    @Published public var parkedThoughts: [ParkedThought] = [
        ParkedThought(text: "Check if flight prices dropped for conference", time: "14:22"),
        ParkedThought(text: "Order replacement mechanical keyboard switches", time: "16:05")
    ]
    @Published public var newThoughtInput: String = ""

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
        encouragementText = "Paused. Take a breath and jump back in when ready."
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
}

// MARK: - SINGLE UNIFIED ADHD VIEW (Removed inactive fake tabs & mockups)
public struct ADHDToolsView: View {
    @ObservedObject var appState = AppState.shared
    @ObservedObject var adhd = ADHDManager.shared

    public var body: some View {
        VStack(spacing: 12) {
            // Focus Sprint Card
            VStack(spacing: 10) {
                // Header
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 11))
                            .foregroundColor(appState.currentTheme.primaryAccent)
                        Text("HYPER-FOCUS SPRINT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .tracking(0.6)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Text("🔥")
                        Text("\(adhd.sprintsCompletedToday) Sprints Won Today")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(6)
                }

                // Single Task Input / Display
                if adhd.isSprintActive {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ACTIVE FOCUS:")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(appState.currentTheme.primaryAccent)
                            Text(adhd.currentTask)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(appState.currentTheme.primaryAccent.opacity(0.15))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(appState.currentTheme.primaryAccent.opacity(0.4), lineWidth: 1)
                    )
                } else {
                    TextField("What single task are you conquering right now?", text: $adhd.currentTask)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, weight: .medium))
                        .padding(10)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 0.8))
                }

                // Timer + Presets
                HStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(formatTime(adhd.secondsRemaining))
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(adhd.isSprintActive ? .white : .white.opacity(0.85))

                        Text(adhd.encouragementText)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                            .lineLimit(1)
                    }

                    Spacer()

                    // Presets
                    if !adhd.isSprintActive {
                        HStack(spacing: 5) {
                            ForEach([5, 10, 15, 25, 45], id: \.self) { mins in
                                Button(action: {
                                    adhd.sprintMinutes = mins
                                    adhd.secondsRemaining = mins * 60
                                }) {
                                    Text("\(mins)m")
                                        .font(.system(size: 10, weight: adhd.sprintMinutes == mins ? .bold : .medium))
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 5)
                                        .background(adhd.sprintMinutes == mins ? appState.currentTheme.primaryAccent : Color.white.opacity(0.06))
                                        .cornerRadius(6)
                                        .foregroundColor(.white)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // Action Buttons
                HStack(spacing: 10) {
                    if !adhd.isSprintActive {
                        Button(action: { adhd.startSprint() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "play.fill")
                                Text("Start \(adhd.sprintMinutes)m Sprint")
                            }
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(appState.currentTheme.primaryAccent)
                            .foregroundColor(.white)
                            .cornerRadius(7)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button(action: { adhd.pauseSprint() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "pause.fill")
                                Text("Pause")
                            }
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Color.white.opacity(0.12))
                            .foregroundColor(.white)
                            .cornerRadius(7)
                        }
                        .buttonStyle(.plain)

                        Button(action: { adhd.completeSprint() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Complete & Win")
                            }
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(7)
                        }
                        .buttonStyle(.plain)

                        Button(action: { adhd.snoozeSprint(extraMinutes: 5) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                Text("5m")
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(.white)
                            .cornerRadius(7)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.035))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 0.8))

            // Distraction Vault (Brain Dump)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("BRAIN DUMP & DISTRACTION VAULT")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(0.6)

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
                    .frame(maxHeight: 80)
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.025))
            .cornerRadius(10)
        }
        .padding(14)
    }

    private func formatTime(_ totalSeconds: Int) -> String {
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
