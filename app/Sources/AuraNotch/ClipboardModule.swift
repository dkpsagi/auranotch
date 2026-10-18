import SwiftUI
import AppKit

public enum ClipType: String, CaseIterable, Identifiable {
    case all = "All"
    case text = "Text"
    case link = "Links"
    case code = "Code"
    case color = "Colors"

    public var id: String { rawValue }
}

public struct ClipItem: Identifiable {
    public let id = UUID()
    public let content: String
    public let type: ClipType
    public let timestamp: Date = Date()
    public var isStarred: Bool = false
}

public class ClipboardManager: ObservableObject {
    public static let shared = ClipboardManager()

    @Published public var clips: [ClipItem] = []
    @Published public var selectedFilter: ClipType = .all
    @Published public var searchQuery: String = ""
    @Published public var latestCopiedPreview: String = "No clips yet"

    private var lastChangeCount: Int = 0
    private var timer: Timer?

    public init() {
        // Read current pasteboard on startup
        let p = NSPasteboard.general
        lastChangeCount = p.changeCount
        if let current = p.string(forType: .string), !current.isEmpty {
            let item = makeClipItem(current)
            clips.append(item)
            latestCopiedPreview = current
        }

        // Start listening to live pasteboard events every 0.6 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { [weak self] _ in
            self?.checkForNewClips()
        }
    }

    public func checkForNewClips() {
        let p = NSPasteboard.general
        guard p.changeCount != lastChangeCount else { return }
        lastChangeCount = p.changeCount

        // Filter out password managers and concealed types
        let types = p.types ?? []
        let sensitive = types.contains { t in
            let raw = t.rawValue
            return raw.contains("ConcealedType") || raw.contains("onepassword") || raw.contains("bitwarden")
        }
        guard !sensitive else { return }

        guard let text = p.string(forType: .string), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Don't add duplicate if it's the exact same as the top item
        if let top = clips.first, top.content == text {
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let newItem = self.makeClipItem(text)
            self.clips.insert(newItem, at: 0)
            self.latestCopiedPreview = text

            // Limit history to 50 items
            if self.clips.count > 50 {
                self.clips.removeLast()
            }
        }
    }

    private func makeClipItem(_ text: String) -> ClipItem {
        var type: ClipType = .text
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            type = .link
        } else if trimmed.hasPrefix("#") && (trimmed.count == 7 || trimmed.count == 4) {
            type = .color
        } else if trimmed.contains("func ") || trimmed.contains("import ") || trimmed.contains("let ") || trimmed.contains("const ") || trimmed.contains("def ") || trimmed.contains("class ") {
            type = .code
        }
        return ClipItem(content: text, type: type)
    }

    public var filteredClips: [ClipItem] {
        clips.filter { item in
            let matchesType = (selectedFilter == .all || item.type == selectedFilter)
            let matchesSearch = searchQuery.isEmpty || item.content.localizedCaseInsensitiveContains(searchQuery)
            return matchesType && matchesSearch
        }
    }

    public func copyToPasteboard(item: ClipItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.content, forType: .string)
        lastChangeCount = pasteboard.changeCount
        latestCopiedPreview = item.content
    }

    public func deleteClip(id: UUID) {
        clips.removeAll { $0.id == id }
    }

    public func clearAll() {
        clips.removeAll()
        latestCopiedPreview = "Cleared"
    }
}

public struct ClipboardHistoryView: View {
    @ObservedObject var clipMgr = ClipboardManager.shared
    @State private var copiedNotice: String? = nil

    public var body: some View {
        VStack(spacing: 10) {
            // Live Status Banner
            HStack(spacing: 8) {
                Image(systemName: "circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 8))

                Text("Live System Clipboard:")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))

                Text(clipMgr.latestCopiedPreview)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()

                if !clipMgr.clips.isEmpty {
                    Button(action: { clipMgr.clearAll() }) {
                        Text("Clear All")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.06))
            .cornerRadius(8)

            // Search and Category Filter
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.4))
                        .font(.system(size: 12))
                    TextField("Search clipboard history...", text: $clipMgr.searchQuery)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.08))
                .cornerRadius(8)

                Picker("Filter", selection: $clipMgr.selectedFilter) {
                    ForEach(ClipType.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 240)
            }

            // Clipboard Item List
            if clipMgr.filteredClips.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.2))
                    Text("Copy text anywhere on your Mac to see it here live.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                    Spacer()
                }
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 6) {
                        ForEach(clipMgr.filteredClips) { clip in
                            HStack(spacing: 10) {
                                Image(systemName: iconForType(clip.type))
                                    .font(.system(size: 12))
                                    .foregroundColor(colorForType(clip.type))
                                    .frame(width: 20)

                                Text(clip.content)
                                    .font(.system(size: 12, design: clip.type == .code ? .monospaced : .default))
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)

                                Spacer()

                                // Character count badge
                                Text("\(clip.content.count) chars")
                                    .font(.system(size: 9))
                                    .foregroundColor(.white.opacity(0.35))

                                // Re-copy button
                                Button(action: {
                                    clipMgr.copyToPasteboard(item: clip)
                                    copiedNotice = "Copied!"
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                        copiedNotice = nil
                                    }
                                }) {
                                    HStack(spacing: 3) {
                                        Image(systemName: "arrow.uturn.backward.circle.fill")
                                        Text("Re-Copy")
                                    }
                                    .font(.system(size: 10, weight: .semibold))
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.35))
                                    .foregroundColor(.blue)
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)

                                // Delete clip
                                Button(action: { clipMgr.deleteClip(id: clip.id) }) {
                                    Image(systemName: "xmark.circle")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(8)
                        }
                    }
                }
            }

            if let notice = copiedNotice {
                Text(notice)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.green)
            }
        }
        .padding(14)
    }

    private func iconForType(_ type: ClipType) -> String {
        switch type {
        case .all: return "doc.text"
        case .text: return "text.quote"
        case .link: return "link"
        case .code: return "curlybraces"
        case .color: return "paintpalette.fill"
        }
    }

    private func colorForType(_ type: ClipType) -> Color {
        switch type {
        case .all: return .white
        case .text: return .blue
        case .link: return .cyan
        case .code: return .purple
        case .color: return .orange
        }
    }
}
