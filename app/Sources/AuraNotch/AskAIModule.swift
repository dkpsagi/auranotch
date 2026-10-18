import SwiftUI

public struct ChatMessage: Identifiable {
    public let id = UUID()
    public let text: String
    public let isUser: Bool
    public let timestamp: Date = Date()
}

public class AskAIManager: ObservableObject {
    public static let shared = AskAIManager()

    @Published public var messages: [ChatMessage] = [
        ChatMessage(text: "Hello! I am Aura Intelligence, your private on-device copilot. Your prompts never leave this Mac. How can I assist you right now?", isUser: false)
    ]
    @Published public var inputText: String = ""
    @Published public var isGenerating: Bool = false

    public func sendMessage(_ prompt: String) {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        messages.append(ChatMessage(text: prompt, isUser: true))
        inputText = ""
        isGenerating = true

        // Simulate fast local neural engine response
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self = self else { return }
            self.isGenerating = false
            let response = self.generateLocalResponse(for: prompt)
            self.messages.append(ChatMessage(text: response, isUser: false))
        }
    }

    private func generateLocalResponse(for prompt: String) -> String {
        let lower = prompt.lowercased()
        if lower.contains("rewrite") {
            return "✨ Here is a polished, punchy rewrite:\n\n\"Elevate your workflow with AuraNotch — turning display dead space into a seamless productivity powerhouse.\""
        } else if lower.contains("summarize") {
            return "📌 Key Takeaways:\n1. 100% on-device local execution.\n2. Zero telemetry & maximum privacy.\n3. Instant hover access right beneath the camera notch."
        } else if lower.contains("code") || lower.contains("swift") {
            return "```swift\n// Clean SwiftUI liquid spring animation\nwithAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {\n    appState.isExpanded.toggle()\n}\n```"
        } else {
            return "Processed securely on-device via Apple Foundation Models: \"\(prompt)\" completed with zero network transmission."
        }
    }
}

public struct AskAIAssistantView: View {
    @ObservedObject var ai = AskAIManager.shared
    private let quickPrompts = ["Rewrite Text", "Summarize Selection", "Fix Grammar", "Explain Code", "Extract Action Items"]

    public var body: some View {
        VStack(spacing: 12) {
            // Privacy Banner
            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.green)
                Text("Private On-Device AI · Apple Intelligence Foundation Models")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text("Zero Cloud Latency")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.06))
            .cornerRadius(8)

            // Chat Messages Stream
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(ai.messages) { msg in
                            HStack(alignment: .top, spacing: 8) {
                                if !msg.isUser {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 13))
                                        .foregroundColor(.purple)
                                        .padding(.top, 4)
                                } else {
                                    Spacer()
                                }

                                Text(msg.text)
                                    .font(.system(size: 13))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(msg.isUser ? Color.purple.opacity(0.7) : Color.white.opacity(0.08))
                                    .cornerRadius(12)
                                    .frame(maxWidth: 420, alignment: msg.isUser ? .trailing : .leading)

                                if msg.isUser {
                                    Image(systemName: "person.crop.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.7))
                                        .padding(.top, 4)
                                }
                            }
                            .id(msg.id)
                        }

                        if ai.isGenerating {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Aura Neural Engine thinking...")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding(.leading, 8)
                        }
                    }
                }
                .onChange(of: ai.messages.count) { _, _ in
                    if let last = ai.messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            // Quick Prompt Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quickPrompts, id: \.self) { prompt in
                        Button(action: { ai.sendMessage(prompt) }) {
                            Text(prompt)
                                .font(.system(size: 11, weight: .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.white.opacity(0.1))
                                .foregroundColor(.white.opacity(0.9))
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Input Bar
            HStack(spacing: 8) {
                TextField("Ask anything or drag text here...", text: $ai.inputText)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .onSubmit {
                        ai.sendMessage(ai.inputText)
                    }

                Button(action: { ai.sendMessage(ai.inputText) }) {
                    ZStack {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 32, height: 32)
                        Image(systemName: "arrow.up")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                .disabled(ai.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
    }
}
