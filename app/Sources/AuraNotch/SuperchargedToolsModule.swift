import SwiftUI
import AppKit
import CoreImage.CIFilterBuiltins

public struct SuperchargedToolsView: View {
    @State private var selectedSubTool = "⚡️ Shortcuts"
    private let subTools = [
        "⚡️ Shortcuts",
        "🌐 Web & Ping",
        "🔤 Dev & Text",
        "🎨 Color & QR",
        "⚖️ Converter"
    ]

    // Real Eyedropper State
    @State private var pickedHex: String = "#7C3AED"
    @State private var copiedNotice: String? = nil

    // QR Code State
    @State private var qrInput: String = "https://auranotch.app"
    @State private var qrImage: NSImage? = nil

    // Converter State
    @State private var convertInput: String = "100"
    @State private var conversionMode: String = "USD to EUR"

    // Internet Ping & URL Cleaner State
    @State private var pingResult: String = "Not tested yet"
    @State private var isPinging: Bool = false
    @State private var urlCleanerInput: String = ""
    @State private var urlCleanedOutput: String = ""
    @State private var urlSavingsNotice: String = ""

    // Dev Text State
    @State private var textTransformerInput: String = "transform this variable name"
    @State private var jsonInput: String = "{\"name\":\"AuraNotch\",\"status\":\"active\",\"pro\":true}"
    @State private var jsonOutput: String = ""
    @State private var jsonStatus: String = "Valid JSON"

    // System States
    @ObservedObject var appState = AppState.shared

    public var body: some View {
        VStack(spacing: 8) {
            // Sub-tool switcher
            Picker("Tools", selection: $selectedSubTool) {
                ForEach(subTools, id: \.self) { tool in
                    Text(tool).tag(tool)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 14)
            .padding(.top, 4)

            // Dynamic SubTool Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    if selectedSubTool == "⚡️ Shortcuts" {
                        shortcutsAndActionsView
                    } else if selectedSubTool == "🌐 Web & Ping" {
                        webAndPingToolsView
                    } else if selectedSubTool == "🔤 Dev & Text" {
                        devAndTextToolsView
                    } else if selectedSubTool == "🎨 Color & QR" {
                        colorAndQRView
                    } else if selectedSubTool == "⚖️ Converter" {
                        converterView
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
            }

            if let notice = copiedNotice {
                Text(notice)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.green)
                    .padding(.bottom, 4)
            }
        }
    }

    // ==========================================
    // 1. SYSTEM & SHORTCUT ACTIONS (OPTIMIZED)
    // ==========================================
    private var shortcutsAndActionsView: some View {
        VStack(spacing: 10) {
            // Section 1: Privacy & Hardware
            VStack(alignment: .leading, spacing: 6) {
                Text("Hardware & Privacy Controls")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .textCase(.uppercase)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    // 1. Hardware Mic Mute
                    actionCard(
                        icon: appState.isMicMuted ? "mic.slash.fill" : "mic.fill",
                        label: appState.isMicMuted ? "Mic Muted (0%)" : "Mute Mic",
                        color: appState.isMicMuted ? .red : .green
                    ) {
                        appState.isMicMuted.toggle()
                        let vol = appState.isMicMuted ? 0 : 100
                        let script = "tell application \"System Events\" to set volume input volume \(vol)"
                        NSAppleScript(source: script)?.executeAndReturnError(nil)
                        showNotice(appState.isMicMuted ? "Microphone Muted (0%)" : "Microphone Active (100%)")
                    }

                    // 2. Hide / Show Desktop Icons (Clean Screen)
                    actionCard(
                        icon: appState.areDesktopIconsHidden ? "eye.slash.fill" : "desktopcomputer",
                        label: appState.areDesktopIconsHidden ? "Icons Hidden" : "Clean Desk",
                        color: appState.areDesktopIconsHidden ? .purple : .cyan
                    ) {
                        appState.areDesktopIconsHidden.toggle()
                        let flag = appState.areDesktopIconsHidden ? "false" : "true"
                        let task = Process()
                        task.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
                        task.arguments = ["write", "com.apple.finder", "CreateDesktop", flag]
                        try? task.run()
                        task.waitUntilExit()

                        let killTask = Process()
                        killTask.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
                        killTask.arguments = ["Finder"]
                        try? killTask.run()

                        showNotice(appState.areDesktopIconsHidden ? "Desktop Icons Hidden (Clean)" : "Desktop Icons Restored")
                    }

                    // 3. Hide Other Apps (Distraction Shield)
                    actionCard(
                        icon: "shield.lefthalf.filled",
                        label: "Shield Others",
                        color: .blue
                    ) {
                        NSWorkspace.shared.hideOtherApplications()
                        showNotice("All other windows minimized")
                    }

                    // 4. Interactive Screenshot
                    actionCard(
                        icon: "camera.viewfinder",
                        label: "Capture (⌘⇧4)",
                        color: .orange
                    ) {
                        let task = Process()
                        task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
                        task.arguments = ["-i", "-c"]
                        try? task.run()
                        showNotice("Drag area to copy screenshot")
                    }
                }
            }

            // Section 2: Window Management & OS Controls
            VStack(alignment: .leading, spacing: 6) {
                Text("Window Management & Utilities")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .textCase(.uppercase)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    // Tile Left
                    actionCard(icon: "rectangle.leadinghalf.filled", label: "Tile Left", color: .indigo) {
                        let script = "tell application \"System Events\" to keystroke \"f\" using {control down, command down}"
                        NSAppleScript(source: script)?.executeAndReturnError(nil)
                    }

                    // Tile Right
                    actionCard(icon: "rectangle.trailinghalf.filled", label: "Tile Right", color: .indigo) {
                        let script = "tell application \"System Events\" to keystroke \"f\" using {control down, command down}"
                        NSAppleScript(source: script)?.executeAndReturnError(nil)
                    }

                    // Toggle Dark Theme
                    actionCard(icon: "circle.righthalf.filled", label: "Toggle Theme", color: .yellow) {
                        let script = "tell application \"System Events\" to tell appearance preferences to set dark mode to not dark mode"
                        NSAppleScript(source: script)?.executeAndReturnError(nil)
                        showNotice("Toggled Dark / Light Mode")
                    }

                    // Empty Trash
                    actionCard(icon: "trash.fill", label: "Empty Trash", color: .red) {
                        let script = "tell application \"Finder\" to empty trash"
                        NSAppleScript(source: script)?.executeAndReturnError(nil)
                        showNotice("Trash Emptied")
                    }

                    // Lock Screen
                    actionCard(icon: "lock.fill", label: "Lock Mac", color: .blue) {
                        let script = "tell application \"System Events\" to keystroke \"q\" using {control down, command down}"
                        NSAppleScript(source: script)?.executeAndReturnError(nil)
                    }

                    // Sleep Displays
                    actionCard(icon: "display", label: "Sleep Screens", color: .teal) {
                        let task = Process()
                        task.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
                        task.arguments = ["displaysleepnow"]
                        try? task.run()
                    }

                    // Open Terminal
                    actionCard(icon: "terminal.fill", label: "Terminal", color: .white) {
                        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app"))
                    }

                    // Force Quit Applications
                    actionCard(icon: "xmark.octagon.fill", label: "Force Quit...", color: .red) {
                        let script = "tell application \"System Events\" to key code 53 using {command down, option down}"
                        NSAppleScript(source: script)?.executeAndReturnError(nil)
                    }
                }
            }
        }
    }

    // ==========================================
    // 2. INTERNET & WEB TOOLS
    // ==========================================
    private var webAndPingToolsView: some View {
        VStack(spacing: 12) {
            // Live Internet Ping Latency Tester
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Live Internet Latency Test")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text(pingResult)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(pingResult.contains("ms") ? .green : .white.opacity(0.6))
                }

                HStack {
                    Button(action: runPingTest) {
                        HStack(spacing: 5) {
                            Image(systemName: isPinging ? "arrow.clockwise" : "network")
                            Text(isPinging ? "Pinging..." : "Test Latency (1.1.1.1)")
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .disabled(isPinging)

                    Spacer()

                    Text("Direct DNS probe to Cloudflare edge")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.45))
                }
            }
            .padding(10)
            .background(Color.white.opacity(0.04))
            .cornerRadius(8)

            // Clean Tracking URLs (Strip UTM, fbclid, etc.)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Clean URL (Strip Tracking UTM & Ads)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    if !urlSavingsNotice.isEmpty {
                        Text(urlSavingsNotice)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.green)
                    }
                }

                HStack(spacing: 8) {
                    TextField("Paste link with tracking params...", text: $urlCleanerInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                        .padding(6)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(6)
                        .foregroundColor(.white)

                    Button(action: {
                        if let clip = NSPasteboard.general.string(forType: .string) {
                            urlCleanerInput = clip
                            cleanURL()
                        }
                    }) {
                        Text("Paste & Clean")
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }

                if !urlCleanedOutput.isEmpty {
                    HStack {
                        Text(urlCleanedOutput)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white.opacity(0.85))
                            .lineLimit(1)

                        Spacer()

                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(urlCleanedOutput, forType: .string)
                            showNotice("Clean URL copied!")
                        }) {
                            Text("Copy")
                                .font(.system(size: 10, weight: .semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.white.opacity(0.12))
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(6)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(6)
                }
            }
            .padding(10)
            .background(Color.white.opacity(0.04))
            .cornerRadius(8)

            // Quick Web Launchers
            VStack(alignment: .leading, spacing: 6) {
                Text("Quick Web Lookups")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .textCase(.uppercase)

                HStack(spacing: 6) {
                    webSearchButton(title: "Google", url: "https://www.google.com")
                    webSearchButton(title: "Perplexity AI", url: "https://www.perplexity.ai")
                    webSearchButton(title: "GitHub", url: "https://github.com")
                    webSearchButton(title: "YouTube", url: "https://www.youtube.com")
                    webSearchButton(title: "DevDocs", url: "https://devdocs.io")
                }
            }
            .padding(10)
            .background(Color.white.opacity(0.04))
            .cornerRadius(8)
        }
    }

    private func webSearchButton(title: String, url: String) -> some View {
        Button(action: {
            if let targetURL = URL(string: url) {
                NSWorkspace.shared.open(targetURL)
            }
        }) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.08))
                .foregroundColor(.white.opacity(0.85))
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    private func runPingTest() {
        isPinging = true
        pingResult = "Measuring latency..."

        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/sbin/ping")
            task.arguments = ["-c", "1", "-W", "1200", "1.1.1.1"]
            let pipe = Pipe()
            task.standardOutput = pipe
            try? task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            DispatchQueue.main.async {
                self.isPinging = false
                if let range = output.range(of: "time=") {
                    let sub = output[range.upperBound...]
                    if let end = sub.firstIndex(of: " ") {
                        let ms = String(sub[..<end])
                        self.pingResult = "⚡️ \(ms) ms (Cloudflare DNS)"
                        return
                    }
                }
                self.pingResult = "Ping failed / Offline"
            }
        }
    }

    private func cleanURL() {
        guard var components = URLComponents(string: urlCleanerInput.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            urlCleanedOutput = urlCleanerInput
            return
        }

        let trackingPrefixes = ["utm_", "fbclid", "gclid", "igshid", "msclkid", "mc_eid", "si", "ref", "ref_src"]
        if let queryItems = components.queryItems {
            let filtered = queryItems.filter { item in
                !trackingPrefixes.contains { item.name.lowercased().starts(with: $0) }
            }
            components.queryItems = filtered.isEmpty ? nil : filtered
        }

        let cleaned = components.string ?? urlCleanerInput
        let diff = max(urlCleanerInput.count - cleaned.count, 0)
        self.urlCleanedOutput = cleaned
        self.urlSavingsNotice = "Cleaned! Removed \(diff) tracking bytes"

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(cleaned, forType: .string)
    }

    // ==========================================
    // 3. DEV & TEXT PRODUCTIVITY TOOLS
    // ==========================================
    private var devAndTextToolsView: some View {
        VStack(spacing: 12) {
            // Case Converter
            VStack(alignment: .leading, spacing: 6) {
                Text("Text Case Converter")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)

                TextField("Text to convert...", text: $textTransformerInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                    .padding(6)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(6)
                    .foregroundColor(.white)

                HStack(spacing: 6) {
                    caseButton("camelCase") { toCamelCase(textTransformerInput) }
                    caseButton("snake_case") { toSnakeCase(textTransformerInput) }
                    caseButton("kebab-case") { toKebabCase(textTransformerInput) }
                    caseButton("UPPER") { textTransformerInput.uppercased() }
                    caseButton("lower") { textTransformerInput.lowercased() }
                }
            }
            .padding(10)
            .background(Color.white.opacity(0.04))
            .cornerRadius(8)

            // JSON Formatter / Minifier
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("JSON Formatter & Validator")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text(jsonStatus)
                        .font(.system(size: 10))
                        .foregroundColor(jsonStatus == "Valid JSON" ? .green : .orange)
                }

                TextField("Paste raw JSON...", text: $jsonInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 10, design: .monospaced))
                    .padding(6)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(6)
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    Button(action: formatJSON) {
                        Text("Beautify (Indent 2)")
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(5)
                    }
                    .buttonStyle(.plain)

                    Button(action: minifyJSON) {
                        Text("Minify")
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.1))
                            .foregroundColor(.white)
                            .cornerRadius(5)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(jsonInput, forType: .string)
                        showNotice("JSON copied!")
                    }) {
                        Text("Copy Result")
                            .font(.system(size: 10))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(.white.opacity(0.8))
                            .cornerRadius(5)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Unix Epoch Timestamp
                    Button(action: {
                        let epoch = String(Int(Date().timeIntervalSince1970))
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(epoch, forType: .string)
                        showNotice("Copied Unix Epoch: \(epoch)")
                    }) {
                        Text("Copy Epoch (\(Int(Date().timeIntervalSince1970)))")
                            .font(.system(size: 10, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.cyan)
                            .cornerRadius(5)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color.white.opacity(0.04))
            .cornerRadius(8)
        }
    }

    private func caseButton(_ label: String, transform: @escaping () -> String) -> some View {
        Button(action: {
            let res = transform()
            textTransformerInput = res
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(res, forType: .string)
            showNotice("Copied \(label) to clipboard!")
        }) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.08))
                .foregroundColor(.white)
                .cornerRadius(5)
        }
        .buttonStyle(.plain)
    }

    private func toCamelCase(_ str: String) -> String {
        let words = str.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        guard let first = words.first else { return "" }
        return first.lowercased() + words.dropFirst().map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }.joined()
    }

    private func toSnakeCase(_ str: String) -> String {
        let words = str.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        return words.map { $0.lowercased() }.joined(separator: "_")
    }

    private func toKebabCase(_ str: String) -> String {
        let words = str.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        return words.map { $0.lowercased() }.joined(separator: "-")
    }

    private func formatJSON() {
        guard let data = jsonInput.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data, options: []),
              let formatted = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]),
              let str = String(data: formatted, encoding: .utf8) else {
            jsonStatus = "Invalid JSON"
            return
        }
        jsonInput = str
        jsonStatus = "Valid JSON (Beautified)"
    }

    private func minifyJSON() {
        guard let data = jsonInput.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data, options: []),
              let minified = try? JSONSerialization.data(withJSONObject: json, options: []),
              let str = String(data: minified, encoding: .utf8) else {
            jsonStatus = "Invalid JSON"
            return
        }
        jsonInput = str
        jsonStatus = "Valid JSON (Minified)"
    }

    // ==========================================
    // 4. COLOR & QR GENERATOR
    // ==========================================
    private var colorAndQRView: some View {
        VStack(spacing: 12) {
            // Eyedropper Card
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: pickedHex))
                    .frame(width: 68, height: 68)
                    .shadow(radius: 6)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Native macOS Screen Eyedropper")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)

                    Text(pickedHex)
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)

                    HStack(spacing: 8) {
                        Button(action: triggerNativeColorSampler) {
                            HStack(spacing: 4) {
                                Image(systemName: "eyedropper")
                                Text("Sample Any Pixel")
                            }
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(5)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(pickedHex, forType: .string)
                            showNotice("Copied \(pickedHex)!")
                        }) {
                            Text("Copy HEX")
                                .font(.system(size: 10))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.1))
                                .foregroundColor(.white)
                                .cornerRadius(5)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Spacer()
            }
            .padding(10)
            .background(Color.white.opacity(0.04))
            .cornerRadius(8)

            // Vector QR Card
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                        .frame(width: 72, height: 72)
                    if let image = generateQRCode(from: qrInput) {
                        Image(nsImage: image)
                            .interpolation(.none)
                            .resizable()
                            .frame(width: 64, height: 64)
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Generate Live QR Code")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)

                    TextField("Enter link or text...", text: $qrInput)
                        .textFieldStyle(.plain)
                        .padding(5)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(5)
                        .foregroundColor(.white)
                        .font(.system(size: 10))

                    Button(action: {
                        if let image = generateQRCode(from: qrInput) {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.writeObjects([image])
                            showNotice("QR Code image copied!")
                        }
                    }) {
                        Text("Copy QR Image to Clipboard")
                            .font(.system(size: 9, weight: .semibold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(5)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(10)
            .background(Color.white.opacity(0.04))
            .cornerRadius(8)
        }
    }

    private func triggerNativeColorSampler() {
        if #available(macOS 10.15, *) {
            NSColorSampler().show { selectedColor in
                guard let color = selectedColor?.usingColorSpace(.sRGB) else { return }
                let r = Int(color.redComponent * 255)
                let g = Int(color.greenComponent * 255)
                let b = Int(color.blueComponent * 255)
                let hex = String(format: "#%02X%02X%02X", r, g, b)

                DispatchQueue.main.async {
                    self.pickedHex = hex
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(hex, forType: .string)
                    self.showNotice("Sampled & Copied \(hex)!")
                }
            }
        }
    }

    private func generateQRCode(from string: String) -> NSImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(Data(string.utf8), forKey: "inputMessage")
        guard let output = filter.outputImage else { return nil }
        let rep = NSCIImageRep(ciImage: output)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        return nsImage
    }

    // ==========================================
    // 5. UNIT & CURRENCY CONVERTER
    // ==========================================
    private var converterView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                TextField("Amount", text: $convertInput)
                    .textFieldStyle(.plain)
                    .padding(6)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(6)
                    .foregroundColor(.white)
                    .frame(width: 80)
                    .font(.system(size: 12))

                Picker("", selection: $conversionMode) {
                    Text("USD ➔ EUR").tag("USD to EUR")
                    Text("USD ➔ GBP").tag("USD to GBP")
                    Text("USD ➔ INR").tag("USD to INR")
                    Text("Pixels ➔ REM (16px)").tag("PX to REM")
                    Text("Miles ➔ KM").tag("Miles to KM")
                    Text("Celsius ➔ Fahrenheit").tag("Celsius to F")
                }
                .frame(width: 170)

                Spacer()

                let result = calculateConversion(val: convertInput, mode: conversionMode)
                Text(result)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
            }
            .padding(10)
            .background(Color.white.opacity(0.04))
            .cornerRadius(8)
        }
    }

    private func calculateConversion(val: String, mode: String) -> String {
        guard let num = Double(val) else { return "--" }
        switch mode {
        case "USD to EUR": return String(format: "€%.2f", num * 0.92)
        case "USD to GBP": return String(format: "£%.2f", num * 0.77)
        case "USD to INR": return String(format: "₹%.2f", num * 84.10)
        case "PX to REM": return String(format: "%.3f rem", num / 16.0)
        case "Miles to KM": return String(format: "%.1f km", num * 1.609)
        case "Celsius to F": return String(format: "%.1f °F", (num * 9/5) + 32)
        default: return "\(num)"
        }
    }

    private func actionCard(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(color == .white ? .white : appState.currentTheme.primaryAccent)
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(Color.white.opacity(0.035))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.06), lineWidth: 0.8))
        }
        .buttonStyle(.plain)
    }

    private func showNotice(_ text: String) {
        copiedNotice = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            copiedNotice = nil
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
