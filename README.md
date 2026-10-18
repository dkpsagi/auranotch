# AuraNotch Pro 🚀

> **The Intelligent Camera Notch & HUD for macOS Sonoma & Sequoia**  
> *Pure Swift · Engineered Natively on macOS with 27 Pro Tools & Zero Battery Drain.*

[![License: Proprietary](https://img.shields.io/badge/License-VIP%20Lifetime-purple.svg)](https://buy.polar.sh/polar_cl_kbUCiJQkgYFAtqH2LXEEHbznV6qYJ05HpuOhU1i9gUx)
[![macOS 14+](https://img.shields.io/badge/macOS-14%2B%20%7C%20Sequoia%20Ready-black.svg?logo=apple)](https://dkpsagi.github.io/auranotch/)
[![Live Web Demo](https://img.shields.io/badge/Live%20Demo-GitHub%20Pages-blue.svg)](https://dkpsagi.github.io/auranotch/)
[![Download DMG](https://img.shields.io/badge/Download-AuraNotch.dmg-green.svg)](https://dkpsagi.github.io/auranotch/AuraNotch.dmg)

---

## 🌐 Official Links & Deployment

- **Live Landing Page & Interactive Simulator:** [https://dkpsagi.github.io/auranotch/](https://dkpsagi.github.io/auranotch/)
- **Purchase AuraNotch Lifetime ($5.00 via Polar.sh):** [https://buy.polar.sh/polar_cl_kbUCiJQkgYFAtqH2LXEEHbznV6qYJ05HpuOhU1i9gUx](https://buy.polar.sh/polar_cl_kbUCiJQkgYFAtqH2LXEEHbznV6qYJ05HpuOhU1i9gUx)
- **Order Success & License Key Page:** [https://dkpsagi.github.io/auranotch/success/](https://dkpsagi.github.io/auranotch/success/)
- **Direct Installer Download:** [AuraNotch.dmg](https://dkpsagi.github.io/auranotch/AuraNotch.dmg)

---

## 📁 Repository Overview

```
auranotch/
├── app/                              # Native macOS Swift App (Swift 6 / macOS 14+)
│   ├── Package.swift                 # Swift Package Manager definition
│   ├── build_app.sh                  # One-click standalone .app and .dmg builder
│   ├── AppIcon.icns                  # 10-layer high-resolution macOS application icon
│   └── Sources/AuraNotch/
│       ├── AppMain.swift             # Main entry point & NSStatusItem monochrome notch menu bar icon
│       ├── AppState.swift            # Observable state, notch dimensions & hardware mic mute controls
│       ├── NotchWindowController.swift # NSPanel window manager, screen detection & hover tracking
│       ├── NotchRootView.swift       # Left vertical sidebar & animated glowing edge motion flair
│       ├── NowPlayingModule.swift    # SoundCloud, Spotify, Apple Music, and YouTube transport controls
│       ├── AskAIModule.swift         # Private on-device Apple Intelligence copilot
│       ├── FileShelfModule.swift     # Drag & drop file staging, NSOpenPanel picker & AirDrop flick
│       ├── ClipboardModule.swift     # Privacy-first searchable clipboard history (skips 1Password/Keychain)
│       ├── AIUsageModule.swift       # Live token sync & auto-refresh (Claude Code, Cursor, Gemini, OpenAI)
│       ├── TeleprompterModule.swift  # Under-camera presentation script scroller with WPM control
│       ├── CameraMirrorModule.swift  # Hardware FaceTime HD video mirror with AVCaptureSession
│       ├── TimersModule.swift        # Pomodoro focus session synced with ambient rainstorm/lo-fi audio
│       ├── SystemStatsModule.swift   # Real-time CPU, RAM cache purger, thermals, and battery watts
│       ├── SuperchargedToolsModule.swift # Color Eyedropper, QR Generator, Clean Desk Shield
│       └── SettingsModule.swift      # Multi-note manager & theme customizer (Liquid Glass, Obsidian)
│
├── web/                              # High-Converting Apple-Grade Landing Webpage
│   ├── index.html                    # macOS Sequoia desktop environment & 27 tool screenshot previews
│   ├── success/
│   │   └── index.html                # Post-purchase page: DMG download, Ed25519 key delivery & receipt
│   ├── AuraNotch.dmg                 # Tested, mountable macOS universal installer (Apple Silicon + Intel)
│   ├── app_icon.png                  # High-res web badge asset
│   └── api/
│       ├── webhook.js                # Polar.sh & Stripe webhook listener with Ed25519 key generation
│       └── webhook.py                # Python Flask / Serverless webhook alternative
│
├── vercel.json                       # Clean URL routing for Vercel deployment
└── docs/                             # Strategy & Architecture Documentation
    ├── PAYMENT_GATEWAY_AND_LICENSING.md # Polar.sh 0% MoR setup & Ed25519 offline licensing
    └── BUSINESS_LAUNCH_AND_ACCOUNTS.md  # Apple Notarization, pricing psychology & GTM roadmap
```

---

## ⚡️ Quick Start

### 1. Preview the Webpage & Success Page Locally
```bash
cd web
python3 -m http.server 8080
# Open http://localhost:8080/ in your browser
# Open http://localhost:8080/success/ for the purchase success & download page
```

### 2. Build the Native macOS App & DMG
To build and package the native app bundle and compressed disk image:
```bash
cd app
./build_app.sh
```
This generates:
- `app/build/AuraNotch.app` (standalone signed application)
- `app/build/AuraNotch.dmg` (mountable drag-and-drop installer)

To launch the app immediately:
```bash
open app/build/AuraNotch.app
```
Use global hotkey `⌥ Option + N` or click the monochrome notch icon in the top system menu bar to toggle the HUD.

---

## 🌟 Key Capabilities

1. **Left Vertical Menubar / Sidebar:** Prevents camera notch clipping with 1-click ergonomics.
2. **Glowing Edge Motion Flair:** Continuous traveling neon border glow on hover and expansion.
3. **Hardware Mic Killswitch:** Physically drives input volume to 0% at the macOS hardware level.
4. **Real System Music Sync:** Evaluates and controls SoundCloud, Spotify, Apple Music, and YouTube.
5. **AI Credits & Token Sync:** Direct sign-in and token tracking for Claude Code, Cursor, Gemini, and OpenAI with 5m auto-refresh.
6. **Multi-Note Manager:** Built-in instant local note taking with sidebar search and auto-saving.
7. **Hardware Video Mirror:** Instant 60 FPS FaceTime HD camera preview for call preparation.
8. **100% On-Device & Private:** Zero tracking, zero telemetry, zero background battery drain.
