# Reverse Engineering OmniNotch: Deep Technical & Architectural Analysis

## 1. Executive Summary

**OmniNotch** (`https://omninotch.app`) is a utility for macOS Sonoma (14+) and Sequoia (15+) created by Nikhil Barik (@nerdynikhil). It transforms the MacBook camera notch from unused hardware into a hover-activated or click-activated HUD featuring 20 built-in tools.

OmniNotch is built on top of the open-source MIT project **NotchDrop** (originally authored by Lakr Aream / Lakr233), which established the core technique of drawing over the Mac's notch and detecting drag-and-drop events. OmniNotch expanded NotchDrop's basic file drop shelf into an all-in-one desktop command center.

---

## 2. Low-Level Reverse Engineering: How the App Works Under the Hood

### A. Window Management & Notch Geometry
1. **Screen Notch Detection:**
   - On physical notch MacBook Pro and Air models (M1, M2, M3, M4), AppKit exposes `NSScreen.main?.auxiliaryTopLeftArea` and `auxiliaryTopRightArea`. The gap between them corresponds to the physical notch: approximately **210–220pt wide** and **32–34pt tall**.
   - On notch-less Macs (Mac mini, Mac Studio, iMac, or external displays), the app calculates `screen.frame.midX` and draws a floating synthetic pill with rounded corners (`cornerRadius: 14pt`).
2. **Window Hierarchy & Level:**
   - The app uses an `NSPanel` subclass configured as:
     ```swift
     styleMask = [.borderless, .nonactivatingPanel]
     level = .statusBar // or .popUpMenu / .floating
     collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
     isOpaque = false
     backgroundColor = .clear
     ```
   - This ensures the notch window stays anchored across virtual desktops (Spaces), full-screen apps, and mission control without losing focus.
3. **Hover & Event Tracking:**
   - An `NSTrackingArea` with `[.mouseEnteredAndExited, .activeAlways, .inVisibleRect]` is attached to the notch view.
   - A debounce timer (150ms–250ms) prevents accidental expansions while passing the cursor over the camera.
4. **Fluid Spring Expansion Physics:**
   - The window animates frame expansion downward from `(X, Y_top, Width: 220, Height: 34)` to `(X_center, Y_top - 460, Width: 680, Height: 460)`.
   - SwiftUI spring physics: `animation(.spring(response: 0.35, dampingFraction: 0.78))` creates the fluid "liquid island" feel.

---

## 3. Reverse Engineering the 20 Core Tools

| # | Tool Name | Technical Implementation | Under the Hood Architecture |
|---|---|---|---|
| **1** | **Ask Omni (AI)** | Apple Foundation Models / CoreML | Runs 100% on-device via Apple Intelligence APIs on macOS 15+; zero telemetry. |
| **2** | **Now Playing** | `MediaRemote.framework` / AppleScript | Reads current track, artist, album art from Spotify & Apple Music; displays synced lyrics via LRCLIB. |
| **3** | **File Shelf** | `NSItemProvider` / `onDrop` | Temporary storage in `~/Library/Application Support/` with auto-deletion timer; triggers `NSSharingService(.sendViaAirDrop)`. |
| **4** | **Clipboard History** | `NSPasteboard` change count | Background polling every 500ms; filters sensitive pasteboard markers (`org.nspasteboard.ConcealedType`, 1Password, Bitwarden). |
| **5** | **AI Usage Tracker** | Local file system inspection | Scans CLI token & cache directories (`~/.claude/`, Cursor SQLite DB, Copilot auth tokens) to calculate usage limits without cloud queries. |
| **6** | **Sales Hub** | Keychain + REST polling | Stores read-only API keys in macOS Keychain; polls Stripe, Lemon Squeezy, Polar, Gumroad, Shopify APIs. |
| **7** | **Teleprompter** | Auto-scrolling SwiftUI Text | Floating window below camera lens; synchronized WPM scrolling so eyes stay focused on the webcam. |
| **8** | **Camera Mirror** | `AVFoundation` / `AVCaptureSession` | 1-click video preview layer for pre-call appearance check. |
| **9** | **Timers & Pomodoro** | Swift `Timer` + `AVAudioPlayer` | 25/5 intervals; ambient focus sound generator (white noise, rain); countdown in closed notch pill. |
| **10** | **Calendar & Reminders** | `EventKit.framework` | Requests `EKEventStore` permissions to fetch today's events and Apple Reminders checkboxes. |
| **11** | **System Monitor** | `host_statistics64` / `IOKit` | Real-time CPU %, RAM pressure, SSD space, and Battery status. |
| **12-20** | **Widgets & Utilities** | Built-in Swift parsers | Unit/Currency converter, full Emoji search, Quick Note scratchpad, Shortcuts trigger, Stocks sparklines, WeatherKit. |

---

## 4. AuraNotch: How We Surpassed OmniNotch

In **AuraNotch**, we expanded the feature set from 20 to **27 tools**, adding:
1. **Screen Color Eyedropper:** Instant loupe tool to sample any screen pixel and copy HEX/RGB/HSL.
2. **Vector QR Code Generator:** 1-click generation of SVG QR codes from any text or link.
3. **Hardware Command Bar:** 1-click system mic mute toggle, instant Do Not Disturb toggle, screen lock, display sleep, and trash empty.
4. **Voice Memo & Dictation:** Fast audio recording and local dictation.
5. **Modern Swift 6 & macOS Sequoia Architecture:** Clean modular architecture, fully decoupled state management, and native dark/light theme adaptation.
