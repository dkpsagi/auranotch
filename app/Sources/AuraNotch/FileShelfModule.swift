import SwiftUI
import AppKit

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
        try? FileManager.default.copyItem(at: sourceURL, to: dest)
        loadRealFiles()
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
    @ObservedObject var shelf = FileShelfManager.shared

    public var body: some View {
        VStack(spacing: 10) {
            // Drop target header
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    .foregroundColor(shelf.isHoveringDropZone ? Color.blue : Color.white.opacity(0.2))
                    .background(shelf.isHoveringDropZone ? Color.blue.opacity(0.12) : Color.white.opacity(0.04))

                HStack(spacing: 12) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Drop files here to stage or AirDrop")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Real folder: ~/Library/Application Support/AuraNotch/Shelf/")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                            .lineLimit(1)
                    }
                    Spacer()

                    Button(action: {
                        NSWorkspace.shared.open(shelf.shelfDirectory)
                    }) {
                        Text("Open Shelf Folder")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.15))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)

                    if !shelf.files.isEmpty {
                        Button(action: { shelf.clearAll() }) {
                            Text("Clear")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .frame(height: 64)

            // Staged Files List
            if shelf.files.isEmpty {
                VStack(spacing: 6) {
                    Spacer()
                    Image(systemName: "tray")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.2))
                    Text("Shelf is empty. Drag and drop any file onto this panel to stage it.")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                    Spacer()
                }
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 6) {
                        ForEach(shelf.files) { file in
                            HStack(spacing: 10) {
                                Image(nsImage: NSWorkspace.shared.icon(forFile: file.path.path))
                                    .resizable()
                                    .frame(width: 24, height: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(file.name)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    Text(file.size)
                                        .font(.system(size: 10))
                                        .foregroundColor(.white.opacity(0.5))
                                }

                                Spacer()

                                Button(action: { shelf.openFile(file) }) {
                                    Text("Open")
                                        .font(.system(size: 10, weight: .medium))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.white.opacity(0.1))
                                        .foregroundColor(.white)
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.plain)

                                Button(action: { shelf.triggerAirDrop(for: file) }) {
                                    HStack(spacing: 3) {
                                        Image(systemName: "airdrop")
                                        Text("AirDrop")
                                    }
                                    .font(.system(size: 10, weight: .semibold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.35))
                                    .foregroundColor(.blue)
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)

                                Button(action: { shelf.removeFile(id: file.id) }) {
                                    Image(systemName: "xmark.circle")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.35))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding(14)
    }
}
