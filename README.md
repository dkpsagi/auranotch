# AuraNotch Pro 🚀

> **The Intelligent Camera Notch & HUD for macOS Sonoma & Sequoia**  
> *Reverse-Engineered, Reimagined, and Supercharged with 27 Native Tools.*

---

## 📁 Repository Overview

```
auranotch/
├── app/                              # Native macOS Swift App (Swift 6 / macOS 14+)
│   ├── Package.swift                 # Swift Package Manager definition
│   ├── build_app.sh                  # One-click standalone .app packager script
│   └── Sources/AuraNotch/
│       ├── AppMain.swift             # Main entry point & NSStatusItem menu bar integration
│       ├── AppState.swift            # Observable state, notch dimensions & settings
│       ├── NotchWindowController.swift # NSPanel window manager, screen detection & hover tracking
│       ├── NotchRootView.swift       # Fluid liquid spring UI & tab router
│       ├── NowPlayingModule.swift    # Media player, seekbar & live synced lyrics
│       ├── AskAIModule.swift         # Private on-device Apple Intelligence copilot
│       ├── FileShelfModule.swift     # Drag & drop file staging + AirDrop quick share
│       ├── ClipboardModule.swift     # Privacy-first searchable clipboard history
│       ├── AIUsageModule.swift       # Live token & rate limit meters (Claude, Cursor, Copilot)
│       ├── SalesModule.swift         # Unified multi-gateway revenue tracker (Stripe, Lemon Squeezy, etc.)
│       ├── TeleprompterModule.swift  # Under-camera presentation script scroller
│       ├── CameraMirrorModule.swift  # Pre-call quick video preview mirror
│       ├── TimersModule.swift        # Pomodoro focus session + ambient focus sounds
│       ├── SystemStatsModule.swift   # Real-time CPU, RAM, Disk, and Battery monitors
│       ├── SuperchargedToolsModule.swift # Color Eyedropper, QR Generator, System Actions
│       └── SettingsModule.swift      # Notch customization & offline cryptographic license activator
│
├── web/                              # High-Converting Apple-Grade Landing Webpage
│   └── index.html                    # Responsive site with interactive live notch simulator & checkout
│
└── docs/                             # Strategy & Architecture Documentation
    ├── REVERSE_ENGINEERING.md        # Technical breakdown of OmniNotch & NotchDrop foundations
    ├── PAYMENT_GATEWAY_AND_LICENSING.md # MoR setup, Ed25519 offline licensing & webhook server
    └── BUSINESS_LAUNCH_AND_ACCOUNTS.md  # Apple Notarization, pricing psychology & Product Hunt GTM
```

---

## ⚡️ Quick Start

### 1. Run the Webpage Locally
To preview the landing page with the interactive browser-based notch simulator:
```bash
cd /Users/dkpsagi/.gemini/antigravity/scratch/auranotch/web
python3 -m http.server 8080
# Open http://localhost:8080 in your browser
```

### 2. Build the Native macOS App
To build the native binary using Swift 6:
```bash
cd /Users/dkpsagi/.gemini/antigravity/scratch/auranotch/app
swift build
```

To create a standalone double-clickable `AuraNotch.app` bundle:
```bash
./build_app.sh
open build/AuraNotch.app
```

---

## 🌟 What Sets AuraNotch Apart
- **27 Tools vs 20 in OmniNotch:** Includes Screen Color Eyedropper, Instant QR Code Generator, Hardware Mic Mute, System Actions, and Voice Memos.
- **100% On-Device:** Zero cloud servers, zero analytics, complete offline privacy.
- **Support for All Macs:** Automatically detects physical notch on MacBook Pros/Airs or renders a floating Dynamic Island on notch-less Macs and external displays.
