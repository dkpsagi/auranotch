import SwiftUI
import AppKit

// MARK: - MULTI-NOTE STORAGE & MANAGER
public struct NoteItem: Identifiable, Codable, Equatable {
    public var id: UUID
    public var title: String
    public var content: String
    public var updatedAt: Date

    public init(id: UUID = UUID(), title: String, content: String, updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.content = content
        self.updatedAt = updatedAt
    }
}

public class NotesManager: ObservableObject {
    public static let shared = NotesManager()

    @Published public var notes: [NoteItem] = []
    @Published public var selectedNoteId: UUID?
    @Published public var searchQuery: String = ""

    private let storageKey = "auranotch_multi_notes_v1"

    public init() {
        loadNotes()
        if notes.isEmpty {
            createInitialNotes()
        }
        if selectedNoteId == nil {
            selectedNoteId = notes.first?.id
        }
    }

    public var selectedNote: NoteItem? {
        notes.first(where: { $0.id == selectedNoteId })
    }

    public var filteredNotes: [NoteItem] {
        if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return notes
        }
        let q = searchQuery.lowercased()
        return notes.filter { $0.title.lowercased().contains(q) || $0.content.lowercased().contains(q) }
    }

    public func loadNotes() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([NoteItem].self, from: data) {
            self.notes = decoded
        }
    }

    public func saveNotes() {
        if let encoded = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    public func createNote() {
        let newNote = NoteItem(
            title: "New Note",
            content: "",
            updatedAt: Date()
        )
        notes.insert(newNote, at: 0)
        selectedNoteId = newNote.id
        saveNotes()
    }

    public func deleteNote(id: UUID) {
        notes.removeAll { $0.id == id }
        if selectedNoteId == id {
            selectedNoteId = notes.first?.id
        }
        saveNotes()
    }

    public func updateTitle(_ newTitle: String) {
        guard let id = selectedNoteId, let idx = notes.firstIndex(where: { $0.id == id }) else { return }
        notes[idx].title = newTitle
        notes[idx].updatedAt = Date()
        saveNotes()
    }

    public func updateContent(_ newContent: String) {
        guard let id = selectedNoteId, let idx = notes.firstIndex(where: { $0.id == id }) else { return }
        notes[idx].content = newContent
        notes[idx].updatedAt = Date()
        saveNotes()
    }

    private func createInitialNotes() {
        let initial = [
            NoteItem(
                title: "Welcome to AuraNotch Notes",
                content: """
                # AuraNotch Native Scratchpad
                - Create multiple notes via the left vertical sidebar.
                - Notes are automatically saved locally on your Mac.
                - Zero cloud tracking, completely private.
                - Use for quick meeting notes, clipboard snippets, or task planning.
                """,
                updatedAt: Date()
            ),
            NoteItem(
                title: "Daily Standup Notes",
                content: """
                - [x] Connected real hardware microphone mute toggle
                - [x] Implemented native camera mirror with AVCaptureSession
                - [x] Added left vertical navigation bar
                - [x] Fixed drag-and-drop file shelf
                """,
                updatedAt: Date().addingTimeInterval(-3600)
            )
        ]
        self.notes = initial
        saveNotes()
    }
}

// MARK: - VERTICAL MULTI-NOTE INTERFACE
public struct QuickNotesView: View {
    @ObservedObject var appState = AppState.shared
    @ObservedObject var notesMgr = NotesManager.shared

    public var body: some View {
        HStack(spacing: 0) {
            // LEFT COLUMN: VERTICAL NOTES LIST
            VStack(spacing: 8) {
                // Top Header with + New Note Button
                HStack {
                    Text("Notes")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            notesMgr.createNote()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .bold))
                            Text("New Note")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(appState.currentTheme.primaryAccent.opacity(0.25))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(appState.currentTheme.primaryAccent.opacity(0.5), lineWidth: 0.8)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.top, 10)

                // Search Filter
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                    TextField("Search notes...", text: $notesMgr.searchQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.05))
                .cornerRadius(6)
                .padding(.horizontal, 10)

                Divider()
                    .background(Color.white.opacity(0.08))

                // Vertical List of Notes
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 4) {
                        ForEach(notesMgr.filteredNotes) { note in
                            let isSelected = notesMgr.selectedNoteId == note.id
                            Button(action: {
                                notesMgr.selectedNoteId = note.id
                            }) {
                                HStack(alignment: .top, spacing: 8) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(note.title.isEmpty ? "Untitled Note" : note.title)
                                            .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                            .foregroundColor(isSelected ? .white : .white.opacity(0.85))
                                            .lineLimit(1)

                                        let preview = note.content.replacingOccurrences(of: "\n", with: " ")
                                        Text(preview.isEmpty ? "No content..." : preview)
                                            .font(.system(size: 10))
                                            .foregroundColor(.white.opacity(0.4))
                                            .lineLimit(1)

                                        Text(formatDate(note.updatedAt))
                                            .font(.system(size: 8))
                                            .foregroundColor(.white.opacity(0.3))
                                    }

                                    Spacer()

                                    if isSelected && notesMgr.notes.count > 1 {
                                        Button(action: {
                                            notesMgr.deleteNote(id: note.id)
                                        }) {
                                            Image(systemName: "trash")
                                                .font(.system(size: 10))
                                                .foregroundColor(.red.opacity(0.7))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(
                                    isSelected ?
                                    appState.currentTheme.primaryAccent.opacity(0.2) :
                                    Color.white.opacity(0.02)
                                )
                                .cornerRadius(7)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 7)
                                        .stroke(isSelected ? appState.currentTheme.primaryAccent.opacity(0.4) : Color.clear, lineWidth: 0.8)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
            .frame(width: 200)
            .background(Color.black.opacity(0.25))

            Divider()
                .background(Color.white.opacity(0.08))

            // RIGHT COLUMN: NOTE EDITOR
            VStack(alignment: .leading, spacing: 8) {
                if let selectedNote = notesMgr.selectedNote {
                    // Title field
                    TextField(
                        "Title",
                        text: Binding(
                            get: { selectedNote.title },
                            set: { notesMgr.updateTitle($0) }
                        )
                    )
                    .textFieldStyle(.plain)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 4)

                    Divider()
                        .background(Color.white.opacity(0.06))

                    // Body editor
                    TextEditor(
                        text: Binding(
                            get: { selectedNote.content },
                            set: { notesMgr.updateContent($0) }
                        )
                    )
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)

                    // Footer bar
                    HStack {
                        HStack(spacing: 4) {
                            Circle().fill(Color.green).frame(width: 5, height: 5)
                            Text("Auto-saved locally")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        Spacer()
                        Text("\(selectedNote.content.count) chars")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(.top, 4)
                } else {
                    Spacer()
                    Text("Select or create a note")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                    Spacer()
                }
            }
            .padding(14)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - SETTINGS VIEW (Renamed from Customizer; Aesthetics renamed to Style; Theme previews; Key section removed)
public struct SettingsView: View {
    @ObservedObject var appState = AppState.shared

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                // SECTION 1: STYLE (With Interactive Visual Previews for Themes)
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Style")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                            .textCase(.uppercase)
                        Spacer()
                        Text("Interactive Theme Previews")
                            .font(.system(size: 10))
                            .foregroundColor(appState.currentTheme.primaryAccent)
                    }

                    // Visual theme preview cards
                    HStack(spacing: 10) {
                        ForEach(GlassTheme.allCases) { theme in
                            let isSelected = appState.currentTheme == theme
                            Button(action: {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                    appState.currentTheme = theme
                                }
                            }) {
                                VStack(spacing: 6) {
                                    // Visual preview chip showing actual gradient and accent glow
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(theme.backgroundGradient)
                                            .frame(height: 48)

                                        Circle()
                                            .fill(theme.primaryAccent)
                                            .frame(width: 14, height: 14)
                                            .shadow(color: theme.primaryAccent.opacity(0.8), radius: 6)
                                    }
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                isSelected ? theme.primaryAccent : Color.white.opacity(0.12),
                                                lineWidth: isSelected ? 2 : 1
                                            )
                                    )

                                    Text(theme.rawValue)
                                        .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                                        .foregroundColor(isSelected ? .white : .white.opacity(0.65))
                                        .lineLimit(1)
                                }
                                .padding(6)
                                .background(isSelected ? theme.primaryAccent.opacity(0.12) : Color.white.opacity(0.03))
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Sliders for Glass Opacity and Notch Clearance
                    HStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Glass Opacity:")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Text("\(Int(appState.glassOpacity * 100))%")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            Slider(value: $appState.glassOpacity, in: 0.6...0.99)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Top Notch Safe Clearance:")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Text("\(Int(appState.topNotchClearance)) pt")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            Slider(value: $appState.topNotchClearance, in: 28...64, step: 2)
                        }
                    }
                    .padding(.top, 4)

                    // Edge Motion Flair Toggle
                    Toggle("Glowing Edge Flair in Motion on Hover", isOn: $appState.showEdgeMotionFlair)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.top, 2)
                }
                .padding(14)
                .background(Color.white.opacity(0.04))
                .cornerRadius(12)

                // SECTION 2: TRIGGER & INTERACTION
                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Trigger & Interaction")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                            .textCase(.uppercase)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Open Mode:")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white)
                                Spacer()
                                Picker("", selection: $appState.triggerMode) {
                                    ForEach(NotchTriggerMode.allCases) { mode in
                                        Text(mode.rawValue).tag(mode)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 130)
                            }

                            if appState.triggerMode == .hover {
                                HStack {
                                    Text("Hover Delay:")
                                        .font(.system(size: 11))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Slider(value: $appState.hoverDelayMs, in: 80...400, step: 20)
                                        .frame(width: 90)
                                    Text("\(Int(appState.hoverDelayMs)) ms")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }

                            Toggle("Haptic Click Feedback", isOn: $appState.playHapticFeedback)
                                .font(.system(size: 11))
                                .foregroundColor(.white)

                            Toggle("Show on All Monitors", isOn: $appState.showOnAllScreens)
                                .font(.system(size: 11))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(10)

                    // Sizing Presets
                    VStack(alignment: .leading, spacing: 10) {
                        Text("HUD Size Presets")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                            .textCase(.uppercase)

                        VStack(spacing: 6) {
                            sizePresetButton(title: "Compact", sizeText: "720 × 490 pt", w: 720, h: 490)
                            sizePresetButton(title: "Balanced (Recommended)", sizeText: "780 × 550 pt", w: 780, h: 550)
                            sizePresetButton(title: "Expanded Studio", sizeText: "840 × 600 pt", w: 840, h: 600)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(10)
                }

                // Info Footer
                HStack {
                    HStack(spacing: 6) {
                        Circle().fill(Color.green).frame(width: 6, height: 6)
                        Text("AuraNotch Pro · Version 2.5.0")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                    Text("100% On-Device · Private by Design")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.horizontal, 6)
            }
            .padding(14)
        }
    }

    private func sizePresetButton(title: String, sizeText: String, w: CGFloat, h: CGFloat) -> some View {
        let isCurrent = (appState.expandedWidth == w && appState.expandedHeight == h)
        return Button(action: {
            appState.expandedWidth = w
            appState.expandedHeight = h
            NotchWindowController.shared.updateWindowFrame(animated: true)
        }) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: isCurrent ? .bold : .medium))
                Spacer()
                Text(sizeText)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isCurrent ? appState.currentTheme.primaryAccent.opacity(0.3) : Color.white.opacity(0.05))
            .cornerRadius(6)
            .foregroundColor(isCurrent ? .white : .white.opacity(0.8))
        }
        .buttonStyle(.plain)
    }
}
