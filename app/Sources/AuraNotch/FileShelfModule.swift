import SwiftUI
import AppKit
import UniformTypeIdentifiers

public struct StagedFile: Identifiable {
    public let id = UUID()
    public let name: String
    public let size: String
    public let path: URL
    public let addedAt: Date = Date()
}

public class FileShelfManager: ObservableObject {
    public static let shared = FileShelfManager()

    @Published public var files: [StagedFile] = []
    @Published public var autoExpireHours: Int = 24
    @Published public var isHoveringDropZone: Bool = false

    public let shelfDirectory: URL

    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        shelfDirectory = appSupport.appendingPathComponent("AuraNotch/Shelf", isDirectory: true)
        try? FileManager.default.createDirectory(at: shelfDirectory, withIntermediateDirectories: true)
        loadRealFiles()
    }

    public func loadRealFiles() {
        guard let contents = try? FileManager.default.contentsOfDirectory(at: shelfDirectory, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]) else { return }

        self.files = contents.compactMap { url in
            guard let values = try? url.resourceValues(forKeys: [.fileSizeKey]) else { return nil }
            let sizeBytes = values.fileSize ?? 0
            let formattedSize = ByteCountFormatter.string(fromByteCount: Int64(sizeBytes), countStyle: .file)
            return StagedFile(name: url.lastPathComponent, size: formattedSize, path: url)
        }
    }

    public func addFile(from sourceURL: URL) {
        let dest = shelfDirectory.appendingPathComponent(sourceURL.lastPathComponent)
        try? FileManager.default.removeItem(at: dest)
        do {
            try FileManager.default.copyItem(at: sourceURL, to: dest)
            NSSound(named: "Tink")?.play()
            loadRealFiles()
        } catch {
            print("Failed to copy file to shelf: \(error)")
        }
    }

    public func promptFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.prompt = "Stage File"
        if panel.runModal() == .OK {
            for url in panel.urls {
                addFile(from: url)
            }
        }
    }

    public func removeFile(id: UUID) {
        if let file = files.first(where: { $0.id == id }) {
            try? FileManager.default.removeItem(at: file.path)
        }
        files.removeAll { $0.id == id }
    }

    public func clearAll() {
        for file in files {
            try? FileManager.default.removeItem(at: file.path)
        }
        files.removeAll()
    }

    public func openFile(_ file: StagedFile) {
        NSWorkspace.shared.open(file.path)
    }

    public func revealInFinder(_ file: StagedFile) {
        NSWorkspace.shared.activateFileViewerSelecting([file.path])
    }

    public func triggerAirDrop(for file: StagedFile) {
        let sharingService = NSSharingService(named: .sendViaAirDrop)
        sharingService?.perform(withItems: [file.path])
    }
}

public struct FileShelfView: View {
    @ObservedObject var appState = AppState.shared
    @ObservedObject var shelf = FileShelfManager.shared

    public var body: some View {
        VStack(spacing: 12) {
            // Interactive Drop Target Area
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        shelf.isHoveringDropZone ? appState.currentTheme.primaryAccent : Color.white.opacity(0.18),
                        style: StrokeStyle(lineWidth: shelf.isHoveringDropZone ? 2 : 1.2, dash: [7, 5])
                    )
                    .background(
                        shelf.isHoveringDropZone ?
                        appState.currentTheme.primaryAccent.opacity(0.14) :
                        Color.white.opacity(0.035)
                    )

                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(appState.currentTheme.primaryAccent.opacity(0.2))
                            .frame(width: 42, height: 42)

                        Image(systemName: "tray.and.arrow.down.fill")
                            .font(.system(size: 20))
                            .foregroundColor(appState.currentTheme.primaryAccent)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(shelf.isHoveringDropZone ? "Release to stage files into Notch Shelf" : "Drag & Drop files here to stage or AirDrop")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)

                        Text("Files are staged locally in ~/Library/Application Support/AuraNotch/Shelf/")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.45))
                    }

                    Spacer()

                    Button(action: {
                        shelf.promptFilePicker()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Files...")
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(appState.currentTheme.primaryAccent.opacity(0.25))
                        .foregroundColor(.white)
                        .cornerRadius(7)
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(appState.currentTheme.primaryAccent.opacity(0.5), lineWidth: 0.8)
                        )
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        NSWorkspace.shared.open(shelf.shelfDirectory)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "folder")
                            Text("Open Folder")
                        }
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(7)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .frame(height: 72)
            // Working .onDrop handlers for Finder and System items
            .onDrop(of: ["public.file-url", "public.item", "public.data"], isTargeted: $shelf.isHoveringDropZone) { providers in
                for provider in providers {
                    if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                            var fileURL: URL? = nil
                            if let url = item as? URL {
                                fileURL = url
                            } else if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                                fileURL = url
                            } else if let str = item as? String, let url = URL(string: str) {
                                fileURL = url
                            }
                            if let fileURL = fileURL {
                                DispatchQueue.main.async {
                                    shelf.addFile(from: fileURL)
                                }
                            }
                        }
                    } else {
                        _ = provider.loadObject(ofClass: URL.self) { url, _ in
                            if let url = url {
                                DispatchQueue.main.async {
                                    shelf.addFile(from: url)
                                }
                            }
                        }
                    }
                }
                return true
            }

            // Staged Files Header / Count
            HStack {
                HStack(spacing: 5) {
                    Text("STAGED FILES")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(0.8)
                    Text("(\(shelf.files.count))")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundColor(appState.currentTheme.primaryAccent)
                }

                Spacer()

                if !shelf.files.isEmpty {
                    Button(action: { shelf.clearAll() }) {
                        Text("Clear All")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.red.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)

            // Staged Files List
            if shelf.files.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "tray")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.2))
                    Text("Shelf is currently empty")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                    Text("Drag files from Finder or desktop onto the drop target above to stage them here.")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                    Spacer()
                }
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 6) {
                        ForEach(shelf.files) { file in
                            HStack(spacing: 12) {
                                Image(nsImage: NSWorkspace.shared.icon(forFile: file.path.path))
                                    .resizable()
                                    .frame(width: 26, height: 26)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(file.name)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    Text(file.size)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.5))
                                }

                                Spacer()

                                Button(action: { shelf.openFile(file) }) {
                                    Text("Open")
                                        .font(.system(size: 10, weight: .semibold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.white.opacity(0.08))
                                        .foregroundColor(.white)
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.plain)

                                Button(action: { shelf.revealInFinder(file) }) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 11))
                                        .foregroundColor(.white.opacity(0.7))
                                        .padding(5)
                                        .background(Color.white.opacity(0.06))
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                                .help("Reveal in Finder")

                                Button(action: { shelf.triggerAirDrop(for: file) }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "airdrop")
                                        Text("AirDrop")
                                    }
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.3))
                                    .foregroundColor(.blue)
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)

                                Button(action: { shelf.removeFile(id: file.id) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.035))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 0.8)
                            )
                            // Enable dragging files out
                            .onDrag {
                                NSItemProvider(object: file.path as NSURL)
                            }
                        }
                    }
                }
            }
        }
        .padding(14)
    }
}
