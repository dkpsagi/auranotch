import SwiftUI
import Combine

public enum NotchTab: String, CaseIterable, Identifiable {
    case home = "Home"
    case nowPlaying = "Music"
    case adhd = "ADHD"
    case timers = "Focus"
    case tools = "Shortcuts"
    case aiUsage = "AI Limits"
    case askAI = "Ask AI"
    case quickNotes = "Notes"
    case clipboard = "Clipboard"
    case fileShelf = "Files"
    case cameraMirror = "Mirror"
    case teleprompter = "Prompter"
    case settings = "Settings"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .nowPlaying: return "music.note"
        case .adhd: return "brain.head.profile"
        case .timers: return "timer"
        case .tools: return "bolt.fill"
        case .aiUsage: return "gauge.with.needle"
        case .askAI: return "sparkles"
        case .quickNotes: return "note.text"
        case .clipboard: return "doc.on.clipboard"
        case .fileShelf: return "folder.fill"
        case .cameraMirror: return "camera.fill"
        case .teleprompter: return "text.alignleft"
        case .settings: return "gearshape.fill"
        }
    }
}

public enum NotchTriggerMode: String, CaseIterable, Identifiable {
    case hover = "Hover"
    case click = "Click"
    
    public var id: String { rawValue }
}

public enum GlassTheme: String, CaseIterable, Identifiable {
    case liquidObsidian = "Liquid Obsidian"
    case frostedTitanium = "Frosted Titanium"
    case cyberpunkEmber = "Cyberpunk Ember"
    case midnightSapphire = "Midnight Sapphire"
    case cleanMinimal = "Clean Minimal"

    public var id: String { rawValue }

    public var primaryAccent: Color {
        switch self {
        case .liquidObsidian: return Color.purple
        case .frostedTitanium: return Color.cyan
        case .cyberpunkEmber: return Color.orange
        case .midnightSapphire: return Color.blue
        case .cleanMinimal: return Color.white
        }
    }

    public var secondaryAccent: Color {
        switch self {
        case .liquidObsidian: return Color.indigo
        case .frostedTitanium: return Color.blue
        case .cyberpunkEmber: return Color.red
        case .midnightSapphire: return Color.cyan
        case .cleanMinimal: return Color.gray
        }
    }

    public var backgroundGradient: LinearGradient {
        switch self {
        case .liquidObsidian:
            return LinearGradient(colors: [Color(red: 0.08, green: 0.07, blue: 0.12), Color(red: 0.04, green: 0.04, blue: 0.06)], startPoint: .top, endPoint: .bottom)
        case .frostedTitanium:
            return LinearGradient(colors: [Color(red: 0.10, green: 0.12, blue: 0.15), Color(red: 0.05, green: 0.06, blue: 0.08)], startPoint: .top, endPoint: .bottom)
        case .cyberpunkEmber:
            return LinearGradient(colors: [Color(red: 0.12, green: 0.07, blue: 0.05), Color(red: 0.06, green: 0.03, blue: 0.03)], startPoint: .top, endPoint: .bottom)
        case .midnightSapphire:
            return LinearGradient(colors: [Color(red: 0.05, green: 0.08, blue: 0.14), Color(red: 0.02, green: 0.04, blue: 0.08)], startPoint: .top, endPoint: .bottom)
        case .cleanMinimal:
            return LinearGradient(colors: [Color(red: 0.08, green: 0.08, blue: 0.08), Color(red: 0.03, green: 0.03, blue: 0.03)], startPoint: .top, endPoint: .bottom)
        }
    }
}

public class AppState: ObservableObject {
    public static let shared = AppState()

    // Notch Expansion State
    @Published public var isExpanded: Bool = false
    @Published public var activeTab: NotchTab = .home
    @Published public var triggerMode: NotchTriggerMode = .hover
    @Published public var hoverDelayMs: Double = 160.0
    @Published public var notchWidth: CGFloat = 220.0
    @Published public var expandedWidth: CGFloat = 780.0
    @Published public var expandedHeight: CGFloat = 550.0
    @Published public var topNotchClearance: CGFloat = 44.0
    @Published public var showOnAllScreens: Bool = true
    @Published public var playHapticFeedback: Bool = true

    // Theme & Styling Customization
    @Published public var currentTheme: GlassTheme = .liquidObsidian
    @Published public var glassOpacity: Double = 0.94
    @Published public var showGlowEffects: Bool = true
    @Published public var showEdgeMotionFlair: Bool = true
    @Published public var customAccentColor: Color = Color.purple

    // License State
    @Published public var isLicensed: Bool = true
    @Published public var licenseKey: String = "AURA-PRO-2026-LIFETIME-VIP"
    @Published public var licenseEmail: String = "pro@auranotch.app"

    // Mini Pill Live Activity indicators (shown on closed notch)
    @Published public var miniStatusText: String = "AuraNotch"
    @Published public var isAudioPlaying: Bool = false
    @Published public var activeTimerSecondsRemaining: Int = 1500
    @Published public var isTimerRunning: Bool = false
    @Published public var isMicMuted: Bool = false
    @Published public var areDesktopIconsHidden: Bool = false

    private init() {
        syncMicMuteState()
    }

    // Physical Hardware Microphone Mute / Unmute
    public func toggleMicMute() {
        isMicMuted.toggle()
        let vol = isMicMuted ? 0 : 75
        let script = "set volume input volume \(vol)"
        var error: NSDictionary?
        _ = NSAppleScript(source: script)?.executeAndReturnError(&error)
    }

    public func syncMicMuteState() {
        DispatchQueue.global(qos: .utility).async {
            let script = "input volume of (get volume settings)"
            var error: NSDictionary?
            if let res = NSAppleScript(source: script)?.executeAndReturnError(&error) {
                let vol = res.int32Value
                DispatchQueue.main.async {
                    self.isMicMuted = (vol == 0)
                }
            }
        }
    }
}
