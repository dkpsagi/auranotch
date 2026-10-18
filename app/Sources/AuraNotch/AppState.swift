import SwiftUI
import Combine

public enum NotchTabCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case adhd = "🧠 ADHD & Focus"
    case shortcuts = "⚡️ Shortcuts & Web"
    case aiSystem = "🤖 AI & System"
    case settings = "⚙️ Customizer"

    public var id: String { rawValue }
}

public enum NotchTab: String, CaseIterable, Identifiable {
    case home = "Home"
    case adhd = "ADHD"
    case tools = "Shortcuts"
    case timers = "Focus"
    case nowPlaying = "Music"
    case clipboard = "Clipboard"
    case aiUsage = "AI Limits"
    case askAI = "Ask AI"
    case teleprompter = "Prompter"
    case fileShelf = "Files"
    case sales = "Sales"
    case cameraMirror = "Mirror"
    case quickNotes = "Notes"
    case settings = "Customizer"

    public var id: String { rawValue }

    public var category: NotchTabCategory {
        switch self {
        case .home:
            return .all
        case .adhd, .timers, .teleprompter, .quickNotes:
            return .adhd
        case .tools, .clipboard, .fileShelf, .cameraMirror:
            return .shortcuts
        case .askAI, .aiUsage, .sales, .nowPlaying:
            return .aiSystem
        case .settings:
            return .settings
        }
    }

    public var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .adhd: return "brain.head.profile"
        case .tools: return "bolt.fill"
        case .clipboard: return "doc.on.clipboard"
        case .nowPlaying: return "music.note"
        case .aiUsage: return "gauge.with.needle"
        case .askAI: return "sparkles"
        case .teleprompter: return "text.alignleft"
        case .timers: return "timer"
        case .fileShelf: return "tray.and.arrow.down"
        case .sales: return "chart.line.uptrend.xyaxis"
        case .cameraMirror: return "camera"
        case .quickNotes: return "note.text"
        case .settings: return "slider.horizontal.3"
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
    @Published public var expandedWidth: CGFloat = 750.0
    @Published public var expandedHeight: CGFloat = 540.0
    @Published public var topNotchClearance: CGFloat = 44.0
    @Published public var showOnAllScreens: Bool = true
    @Published public var playHapticFeedback: Bool = true

    // Theme & Styling Customization
    @Published public var currentTheme: GlassTheme = .liquidObsidian
    @Published public var glassOpacity: Double = 0.94
    @Published public var showGlowEffects: Bool = true
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

    // Navigation Category Filter
    @Published public var selectedTabCategory: NotchTabCategory = .all

    private init() {}
}
