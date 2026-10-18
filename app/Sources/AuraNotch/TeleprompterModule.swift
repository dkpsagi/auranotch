import SwiftUI
import AppKit

public class TeleprompterManager: ObservableObject {
    public static let shared = TeleprompterManager()

    @Published public var scriptText: String = """
    Good afternoon everyone, and welcome to the presentation of AuraNotch for Mac.

    Today, we're unveiling how we turned the MacBook camera notch from dead screen space into a seamless command center.

    With on-device intelligence, instant media control, and unified developer metrics, your workflow is now a glance away.

    Let's dive right into the live demonstration.
    """
    @Published public var isScrolling: Bool = false
    @Published public var scrollSpeedWPM: Double = 140.0
    @Published public var fontSize: CGFloat = 16.0
    @Published public var isMirrored: Bool = false
    @Published public var scrollOffset: CGFloat = 0.0
    @Published public var isEditing: Bool = false

    private var timer: Timer?

    public var wordCount: Int {
        let words = scriptText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        return words.count
    }

    public var estimatedTimeMinutes: Double {
        return max(Double(wordCount) / max(scrollSpeedWPM, 60), 0.1)
    }

    public func togglePlay() {
        isScrolling.toggle()
        if isScrolling {
            isEditing = false
            startScroll()
        } else {
            stopScroll()
        }
    }

    private func startScroll() {
        timer?.invalidate()
        let interval = 0.04
        let step = (scrollSpeedWPM / 120.0) * 0.8
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.scrollOffset += CGFloat(step)
            }
        }
    }

    public func stopScroll() {
        timer?.invalidate()
        timer = nil
    }

    public func reset() {
        stopScroll()
        isScrolling = false
        scrollOffset = 0.0
    }

    public func pasteFromClipboard() {
        if let str = NSPasteboard.general.string(forType: .string), !str.isEmpty {
            self.scriptText = str
            reset()
        }
    }

    public func clearScript() {
        self.scriptText = ""
        reset()
    }

    public func copyScript() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(scriptText, forType: .string)
    }

    public func loadSampleScript() {
        self.scriptText = """
        Welcome everyone. Today I'm demonstrating the new AuraNotch HUD.

        Notice how the teleprompter scrolls directly underneath the camera lens.
        This keeps my eye contact locked straight at the audience during video conferences.

        It works smoothly with adjustable WPM speed, mirrored mode, and instant clipboard sync.
        """
        reset()
    }
}

public struct TeleprompterView: View {
    @ObservedObject var prompter = TeleprompterManager.shared
    @State private var noticeMessage: String? = nil

    public var body: some View {
        VStack(spacing: 10) {
            // Action & Utility Bar
            HStack(spacing: 10) {
                // Play / Pause Button
                Button(action: { prompter.togglePlay() }) {
                    HStack(spacing: 5) {
                        Image(systemName: prompter.isScrolling ? "pause.fill" : "play.fill")
                        Text(prompter.isScrolling ? "Pause" : "Start Scroll")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(prompter.isScrolling ? Color.orange : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(7)
                }
                .buttonStyle(.plain)

                Button(action: { prompter.reset() }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)

                // Edit Mode Toggle
                Button(action: {
                    prompter.stopScroll()
                    prompter.isEditing.toggle()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: prompter.isEditing ? "checkmark.circle.fill" : "pencil")
                        Text(prompter.isEditing ? "Done" : "Edit Script")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(prompter.isEditing ? Color.green.opacity(0.3) : Color.white.opacity(0.1))
                    .foregroundColor(prompter.isEditing ? .green : .white)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)

                // Paste from Clipboard Button
                Button(action: {
                    prompter.pasteFromClipboard()
                    showNotice("Pasted from clipboard!")
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.clipboard")
                        Text("Paste")
                    }
                    .font(.system(size: 11))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.08))
                    .foregroundColor(.white.opacity(0.85))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)

                // Clear Text Button
                Button(action: {
                    prompter.clearScript()
                    showNotice("Script cleared")
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "trash")
                        Text("Clear")
                    }
                    .font(.system(size: 11))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.08))
                    .foregroundColor(.red.opacity(0.8))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)

                // Copy Script Button
                Button(action: {
                    prompter.copyScript()
                    showNotice("Copied script!")
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)

                Spacer()

                // Speed Slider
                HStack(spacing: 5) {
                    Text("Speed:")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.45))
                    Slider(value: $prompter.scrollSpeedWPM, in: 80...260, step: 10)
                        .frame(width: 80)
                    Text("\(Int(prompter.scrollSpeedWPM)) WPM")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                }

                // Mirror toggle
                Button(action: { prompter.isMirrored.toggle() }) {
                    Image(systemName: prompter.isMirrored ? "arrow.left.and.right.righttriangle.left.righttriangle.right.fill" : "arrow.left.and.right.righttriangle.left.righttriangle.right")
                        .font(.system(size: 12))
                        .foregroundColor(prompter.isMirrored ? .blue : .white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.top, 2)

            // Statistics bar
            HStack(spacing: 12) {
                Text("\(prompter.wordCount) words")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                Text("·")
                    .foregroundColor(.white.opacity(0.3))
                Text(String(format: "Est. speaking time: ~%.1f min", prompter.estimatedTimeMinutes))
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()

                if let notice = noticeMessage {
                    Text(notice)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green)
                } else {
                    Button(action: { prompter.loadSampleScript() }) {
                        Text("Load Sample Speech")
                            .font(.system(size: 10))
                            .foregroundColor(.purple)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)

            // Live Script Screen
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.65))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )

                if prompter.isEditing {
                    // Script Editor Mode
                    TextEditor(text: $prompter.scriptText)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.white)
                        .scrollContentBackground(.hidden)
                        .padding(12)
                } else {
                    // Presentation Scrolling Mode
                    VStack(spacing: 0) {
                        // Eye line guide
                        Rectangle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(height: 24)
                            .overlay(
                                Text("CAMERA EYE-LINE GUIDE")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.blue.opacity(0.6))
                            )

                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 14) {
                                Text(prompter.scriptText.isEmpty ? "No script loaded. Click 'Paste' or 'Edit Script' above." : prompter.scriptText)
                                    .font(.system(size: prompter.fontSize, weight: .medium, design: .rounded))
                                    .foregroundColor(prompter.scriptText.isEmpty ? .white.opacity(0.3) : .white)
                                    .lineSpacing(6)
                                    .scaleEffect(x: prompter.isMirrored ? -1 : 1, y: 1)
                                    .offset(y: -prompter.scrollOffset)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(16)
                        }
                    }
                }
            }
            .frame(height: 240)
        }
        .padding(12)
    }

    private func showNotice(_ text: String) {
        noticeMessage = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            noticeMessage = nil
        }
    }
}
