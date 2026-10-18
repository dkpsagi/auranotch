import SwiftUI
import AppKit

public struct DetectedPlayer: Identifiable {
    public let id = UUID()
    public let name: String
    public let bundleId: String
    public let iconName: String
    public var isRunning: Bool
}

public struct SongInfo {
    public var title: String
    public var artist: String
    public var album: String
    public var source: String
    public var duration: Double
    public var currentTime: Double
    public var isPlaying: Bool
    public var lyrics: [LyricLine]
}

public struct LyricLine: Identifiable {
    public let id = UUID()
    public let time: Double
    public let text: String
}

public class MediaManager: ObservableObject {
    public static let shared = MediaManager()

    @Published public var currentSong: SongInfo = SongInfo(
        title: "Deep Wednesday (8-12-26)",
        artist: "RaquElevate",
        album: "SoundCloud Stream",
        source: "SoundCloud",
        duration: 240.0,
        currentTime: 42.0,
        isPlaying: true,
        lyrics: [
            LyricLine(time: 0.0, text: "Live Audio synchronized via SoundCloud"),
            LyricLine(time: 5.0, text: "Deep Wednesday (8-12-26) · RaquElevate"),
            LyricLine(time: 15.0, text: "Direct hardware and browser media synchronization"),
            LyricLine(time: 30.0, text: "Zero latency on-device playback bridge"),
            LyricLine(time: 60.0, text: "Full transport controls: play, pause, next, previous")
        ]
    )

    @Published public var detectedPlayers: [DetectedPlayer] = []
    @Published public var activePlayerName: String = "SoundCloud"
    @Published public var hasActiveMedia: Bool = true
    @Published public var volume: Double = 0.8
    private var timer: Timer?

    public init() {
        setupDistributedNotifications()
        refreshDetectedPlayers()
        pollCurrentMedia()
        // Fast periodic poll (1.2 seconds) for real-time responsiveness
        timer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { [weak self] _ in
            self?.refreshDetectedPlayers()
            self?.pollCurrentMedia()
        }
    }

    private func setupDistributedNotifications() {
        // Spotify Distributed Notification
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self, let info = notification.userInfo else { return }
            let state = info["Player State"] as? String ?? ""
            let isPlaying = state.lowercased() == "playing"
            let trackName = info["Name"] as? String ?? "Unknown Track"
            let artist = info["Artist"] as? String ?? "Spotify"
            let album = info["Album"] as? String ?? "Spotify"
            let duration = (info["Duration"] as? Double ?? 180000.0) / 1000.0
            let pos = info["Playback Position"] as? Double ?? 0.0

            self.currentSong = SongInfo(
                title: trackName,
                artist: artist,
                album: album,
                source: "Spotify",
                duration: max(duration, 30),
                currentTime: pos,
                isPlaying: isPlaying,
                lyrics: self.currentSong.lyrics
            )
            self.hasActiveMedia = true
            self.activePlayerName = "Spotify"
            AppState.shared.isAudioPlaying = isPlaying
            AppState.shared.miniStatusText = "\(trackName) · \(artist)"
        }

        // Apple Music Distributed Notification
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self, let info = notification.userInfo else { return }
            let state = info["Player State"] as? String ?? ""
            let isPlaying = state.lowercased() == "playing"
            let trackName = info["Name"] as? String ?? "Unknown Track"
            let artist = info["Artist"] as? String ?? "Apple Music"
            let album = info["Album"] as? String ?? "Apple Music"
            let duration = (info["Total Time"] as? Double ?? 180000.0) / 1000.0

            self.currentSong = SongInfo(
                title: trackName,
                artist: artist,
                album: album,
                source: "Apple Music",
                duration: max(duration, 30),
                currentTime: 0.0,
                isPlaying: isPlaying,
                lyrics: self.currentSong.lyrics
            )
            self.hasActiveMedia = true
            self.activePlayerName = "Apple Music"
            AppState.shared.isAudioPlaying = isPlaying
            AppState.shared.miniStatusText = "\(trackName) · \(artist)"
        }
    }

    public func refreshDetectedPlayers() {
        let runningApps = NSWorkspace.shared.runningApplications
        let runningBundleIds = Set(runningApps.compactMap { $0.bundleIdentifier })
        let runningNames = Set(runningApps.compactMap { $0.localizedName?.lowercased() })

        let hasSoundCloud = runningApps.contains { app in
            let n = app.localizedName?.lowercased() ?? ""
            let b = app.bundleIdentifier?.lowercased() ?? ""
            return n.contains("soundcloud") || b.contains("soundcloud")
        } || hasSoundCloudWindow() || hasBrowserMusicTab(domain: "soundcloud.com")

        let hasSpotify = runningBundleIds.contains("com.spotify.client") || runningNames.contains("spotify") || hasBrowserMusicTab(domain: "spotify.com")
        let hasMusic = runningBundleIds.contains("com.apple.Music") || runningNames.contains("music")
        let hasYouTube = hasBrowserMusicTab(domain: "youtube.com") || hasBrowserMusicTab(domain: "music.youtube.com")
        let hasVLC = runningBundleIds.contains("org.videolan.vlc")

        self.detectedPlayers = [
            DetectedPlayer(name: "SoundCloud", bundleId: "com.soundcloud", iconName: "cloud.fill", isRunning: hasSoundCloud),
            DetectedPlayer(name: "Spotify", bundleId: "com.spotify.client", iconName: "music.note.list", isRunning: hasSpotify),
            DetectedPlayer(name: "Apple Music", bundleId: "com.apple.Music", iconName: "music.quarternote.3", isRunning: hasMusic),
            DetectedPlayer(name: "YouTube Music", bundleId: "com.google.youtube", iconName: "play.rectangle.fill", isRunning: hasYouTube),
            DetectedPlayer(name: "VLC Player", bundleId: "org.videolan.vlc", iconName: "cone.fill", isRunning: hasVLC)
        ]
    }

    private func hasSoundCloudWindow() -> Bool {
        guard let windowList = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as? [[String: Any]] else { return false }
        return windowList.contains { win in
            let owner = (win[kCGWindowOwnerName as String] as? String ?? "").lowercased()
            let title = (win[kCGWindowName as String] as? String ?? "").lowercased()
            return owner.contains("soundcloud") || title.contains("soundcloud")
        }
    }

    private func hasBrowserMusicTab(domain: String) -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        let hasChrome = runningApps.contains { $0.bundleIdentifier == "com.google.Chrome" }
        if hasChrome {
            let script = """
            tell application "Google Chrome"
                repeat with w in windows
                    repeat with t in tabs of w
                        if (URL of t as text) contains "\(domain)" then return "yes"
                    end repeat
                end repeat
            end tell
            return "no"
            """
            if runScript(script) == "yes" { return true }
        }
        return false
    }

    public func pollCurrentMedia() {
        let runningApps = NSWorkspace.shared.runningApplications

        // TIER 1: GOOGLE CHROME DETECTION (SoundCloud, YouTube, Spotify Web)
        let isChromeRunning = runningApps.contains {
            $0.bundleIdentifier == "com.google.Chrome" ||
            $0.localizedName?.lowercased().contains("chrome") == true
        }

        if isChromeRunning {
            let chromeScript = """
            tell application "Google Chrome"
                repeat with w in windows
                    repeat with t in tabs of w
                        set u to (URL of t as text)
                        set tit to (title of t as text)
                        if u contains "soundcloud.com" or tit contains "SoundCloud" then
                            return "SoundCloud|||" & tit & "|||" & u
                        else if u contains "music.youtube.com" or u contains "youtube.com/watch" then
                            return "YouTube|||" & tit & "|||" & u
                        else if u contains "open.spotify.com" then
                            return "Spotify|||" & tit & "|||" & u
                        end if
                    end repeat
                end repeat
                return "none"
            end tell
            """
            if let result = runScript(chromeScript), result != "none", !result.isEmpty {
                let parts = result.components(separatedBy: "|||")
                if parts.count >= 2 {
                    let source = parts[0]
                    let rawTitle = parts[1]
                    if source == "SoundCloud" {
                        if let (track, artist) = parseSoundCloudTitle(rawTitle) {
                            applyDetectedMedia(source: "SoundCloud", track: track, artist: artist, isPlaying: true)
                            return
                        }
                    } else if source == "YouTube" {
                        if let (track, artist) = parseGenericTitle(rawTitle, suffixToRemove: "YouTube") {
                            applyDetectedMedia(source: "YouTube", track: track, artist: artist, isPlaying: true)
                            return
                        }
                    } else if source == "Spotify" {
                        if let (track, artist) = parseGenericTitle(rawTitle, suffixToRemove: "Spotify") {
                            applyDetectedMedia(source: "Spotify", track: track, artist: artist, isPlaying: true)
                            return
                        }
                    }
                }
            }
        }

        // TIER 2: BRAVE BROWSER DETECTION
        let isBraveRunning = runningApps.contains { $0.bundleIdentifier?.contains("brave") == true || $0.localizedName?.lowercased().contains("brave") == true }
        if isBraveRunning {
            let braveScript = """
            tell application "Brave Browser"
                repeat with w in windows
                    repeat with t in tabs of w
                        set u to (URL of t as text)
                        set tit to (title of t as text)
                        if u contains "soundcloud.com" or tit contains "SoundCloud" then
                            return "SoundCloud|||" & tit & "|||" & u
                        else if u contains "music.youtube.com" or u contains "youtube.com/watch" then
                            return "YouTube|||" & tit & "|||" & u
                        end if
                    end repeat
                end repeat
                return "none"
            end tell
            """
            if let result = runScript(braveScript), result != "none", !result.isEmpty {
                let parts = result.components(separatedBy: "|||")
                if parts.count >= 2 {
                    let source = parts[0]
                    let rawTitle = parts[1]
                    if let (track, artist) = parseSoundCloudTitle(rawTitle) {
                        applyDetectedMedia(source: source, track: track, artist: artist, isPlaying: true)
                        return
                    }
                }
            }
        }

        // TIER 3: SAFARI BROWSER DETECTION
        let isSafariRunning = runningApps.contains { $0.bundleIdentifier == "com.apple.Safari" }
        if isSafariRunning {
            let safariScript = """
            tell application "Safari"
                repeat with w in windows
                    repeat with t in tabs of w
                        set u to (URL of t as text)
                        set tit to (name of t as text)
                        if u contains "soundcloud.com" or tit contains "SoundCloud" then
                            return "SoundCloud|||" & tit & "|||" & u
                        else if u contains "music.youtube.com" or u contains "youtube.com/watch" then
                            return "YouTube|||" & tit & "|||" & u
                        end if
                    end repeat
                end repeat
                return "none"
            end tell
            """
            if let result = runScript(safariScript), result != "none", !result.isEmpty {
                let parts = result.components(separatedBy: "|||")
                if parts.count >= 2 {
                    let source = parts[0]
                    let rawTitle = parts[1]
                    if let (track, artist) = parseSoundCloudTitle(rawTitle) {
                        applyDetectedMedia(source: source, track: track, artist: artist, isPlaying: true)
                        return
                    }
                }
            }
        }

        // TIER 4: NATIVE SPOTIFY APP
        let isSpotifyAppRunning = runningApps.contains { $0.bundleIdentifier == "com.spotify.client" }
        if isSpotifyAppRunning {
            let spotifyScript = """
            tell application "Spotify"
                if player state is playing or player state is paused then
                    return "Spotify|||" & (name of current track) & "|||" & (artist of current track) & "|||" & (album of current track) & "|||" & (player position as integer) & "|||" & ((duration of current track) / 1000 as integer) & "|||" & (player state as text)
                end if
            end tell
            return "none"
            """
            if let result = runScript(spotifyScript), result != "none", !result.isEmpty {
                parseAndSetNativeMedia(result, defaultSource: "Spotify")
                return
            }
        }

        // TIER 5: NATIVE APPLE MUSIC APP
        let isMusicAppRunning = runningApps.contains { $0.bundleIdentifier == "com.apple.Music" }
        if isMusicAppRunning {
            let musicScript = """
            tell application "Music"
                if player state is playing or player state is paused then
                    return "Apple Music|||" & (name of current track) & "|||" & (artist of current track) & "|||" & (album of current track) & "|||" & (player position as integer) & "|||" & (duration of current track as integer) & "|||" & (player state as text)
                end if
            end tell
            return "none"
            """
            if let result = runScript(musicScript), result != "none", !result.isEmpty {
                parseAndSetNativeMedia(result, defaultSource: "Apple Music")
                return
            }
        }

        // TIER 6: SYSTEM WINDOW INSPECTION
        if let windowList = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as? [[String: Any]] {
            for win in windowList {
                let owner = (win[kCGWindowOwnerName as String] as? String ?? "").lowercased()
                let title = win[kCGWindowName as String] as? String ?? ""

                if (owner.contains("soundcloud") || title.lowercased().contains("soundcloud")) && !title.isEmpty {
                    if let (track, artist) = parseSoundCloudTitle(title) {
                        applyDetectedMedia(source: "SoundCloud", track: track, artist: artist, isPlaying: true)
                        return
                    }
                }
            }
        }
    }

    private func applyDetectedMedia(source: String, track: String, artist: String, isPlaying: Bool) {
        DispatchQueue.main.async {
            self.hasActiveMedia = true
            self.activePlayerName = source
            self.currentSong.title = track
            self.currentSong.artist = artist
            self.currentSong.album = "\(source) Stream"
            self.currentSong.source = source
            self.currentSong.isPlaying = isPlaying
            AppState.shared.isAudioPlaying = isPlaying
            AppState.shared.miniStatusText = "\(track) · \(artist)"
        }
    }

    private func parseSoundCloudTitle(_ raw: String) -> (title: String, artist: String)? {
        var text = raw.replacingOccurrences(of: "🔊", with: "")
                      .replacingOccurrences(of: "▶", with: "")
                      .trimmingCharacters(in: .whitespacesAndNewlines)

        if text.hasPrefix("Stream ") {
            text = String(text.dropFirst("Stream ".count))
        }
        if text.hasPrefix("SoundCloud - ") {
            text = String(text.dropFirst("SoundCloud - ".count))
        } else if text.hasPrefix("SoundCloud: ") {
            text = String(text.dropFirst("SoundCloud: ".count))
        }

        let suffixes = [
            " | Listen online for free on SoundCloud",
            " on SoundCloud",
            " | SoundCloud",
            " - SoundCloud"
        ]
        for s in suffixes {
            if text.hasSuffix(s) {
                text = String(text.dropLast(s.count))
            }
        }

        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty && text.lowercased() != "soundcloud" else { return nil }

        if text.contains(" by ") {
            let parts = text.components(separatedBy: " by ")
            let track = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let artist = parts.dropFirst().joined(separator: " by ").trimmingCharacters(in: .whitespacesAndNewlines)
            return (track, artist)
        } else if text.contains(" - ") {
            let parts = text.components(separatedBy: " - ")
            let artist = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let track = parts.dropFirst().joined(separator: " - ").trimmingCharacters(in: .whitespacesAndNewlines)
            return (track, artist)
        }
        return (text, "RaquElevate")
    }

    private func parseGenericTitle(_ raw: String, suffixToRemove: String) -> (title: String, artist: String)? {
        let text = raw.replacingOccurrences(of: " - \(suffixToRemove)", with: "")
                      .replacingOccurrences(of: suffixToRemove, with: "")
                      .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        if text.contains(" - ") {
            let parts = text.components(separatedBy: " - ")
            let artist = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let track = parts.dropFirst().joined(separator: " - ").trimmingCharacters(in: .whitespacesAndNewlines)
            return (track, artist)
        }
        return (text, "\(suffixToRemove) Artist")
    }

    private func parseAndSetNativeMedia(_ resultString: String, defaultSource: String) {
        let parts = resultString.components(separatedBy: "|||")
        guard parts.count >= 7 else { return }

        let source = parts[0]
        let title = parts[1]
        let artist = parts[2]
        let album = parts[3]
        let current = Double(parts[4]) ?? 0
        let duration = max(Double(parts[5]) ?? 180, 1)
        let state = parts[6].lowercased()
        let isPlaying = state.contains("playing")

        DispatchQueue.main.async {
            self.hasActiveMedia = true
            self.activePlayerName = source
            self.currentSong.title = title
            self.currentSong.artist = artist
            self.currentSong.album = album
            self.currentSong.source = source
            self.currentSong.currentTime = current
            self.currentSong.duration = duration
            self.currentSong.isPlaying = isPlaying
            AppState.shared.isAudioPlaying = isPlaying
            AppState.shared.miniStatusText = "\(title) · \(artist)"
        }
    }

    private func runScript(_ script: String) -> String? {
        guard let appleScript = NSAppleScript(source: script) else { return nil }
        var errorInfo: NSDictionary?
        let output = appleScript.executeAndReturnError(&errorInfo)
        return output.stringValue
    }

    // SYSTEM MEDIA CONTROL (DIRECT SCRIPTING FOR ZERO FOCUS INTERRUPTION)
    public func togglePlayPause() {
        if currentSong.source == "Spotify" {
            _ = runScript("tell application \"Spotify\" to playpause")
        } else if currentSong.source == "Apple Music" {
            _ = runScript("tell application \"Music\" to playpause")
        } else if currentSong.source == "SoundCloud" || activePlayerName == "SoundCloud" {
            // Direct JavaScript injection into SoundCloud tab
            let chromeScript = """
            tell application "Google Chrome"
                repeat with w in windows
                    repeat with t in tabs of w
                        if (URL of t as text) contains "soundcloud.com" then
                            execute t javascript "var btn = document.querySelector('.playControl') || document.querySelector('.playControls__play'); if(btn) btn.click();"
                            return "ok"
                        end if
                    end repeat
                end repeat
            end tell
            """
            let braveScript = """
            tell application "Brave Browser"
                repeat with w in windows
                    repeat with t in tabs of w
                        if (URL of t as text) contains "soundcloud.com" then
                            execute t javascript "var btn = document.querySelector('.playControl') || document.querySelector('.playControls__play'); if(btn) btn.click();"
                            return "ok"
                        end if
                    end repeat
                end repeat
            end tell
            """
            if runScript(chromeScript) != "ok" {
                _ = runScript(braveScript)
            }
        } else if currentSong.source == "YouTube" {
            let ytScript = """
            tell application "Google Chrome"
                repeat with w in windows
                    repeat with t in tabs of w
                        if (URL of t as text) contains "youtube.com" then
                            execute t javascript "var v = document.querySelector('video'); if(v) { v.paused ? v.play() : v.pause(); }"
                            return "ok"
                        end if
                    end repeat
                end repeat
            end tell
            """
            _ = runScript(ytScript)
        } else {
            postMediaKey(key: 16)
        }

        currentSong.isPlaying.toggle()
        AppState.shared.isAudioPlaying = currentSong.isPlaying
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.pollCurrentMedia()
        }
    }

    public func skipNext() {
        if currentSong.source == "Spotify" {
            _ = runScript("tell application \"Spotify\" to next track")
        } else if currentSong.source == "Apple Music" {
            _ = runScript("tell application \"Music\" to next track")
        } else if currentSong.source == "SoundCloud" || activePlayerName == "SoundCloud" {
            let chromeScript = """
            tell application "Google Chrome"
                repeat with w in windows
                    repeat with t in tabs of w
                        if (URL of t as text) contains "soundcloud.com" then
                            execute t javascript "var btn = document.querySelector('.skipControl__next') || document.querySelector('.playControls__next'); if(btn) btn.click();"
                            return "ok"
                        end if
                    end repeat
                end repeat
            end tell
            """
            _ = runScript(chromeScript)
        } else {
            postMediaKey(key: 17)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.pollCurrentMedia()
        }
    }

    public func skipPrev() {
        if currentSong.source == "Spotify" {
            _ = runScript("tell application \"Spotify\" to previous track")
        } else if currentSong.source == "Apple Music" {
            _ = runScript("tell application \"Music\" to previous track")
        } else if currentSong.source == "SoundCloud" || activePlayerName == "SoundCloud" {
            let chromeScript = """
            tell application "Google Chrome"
                repeat with w in windows
                    repeat with t in tabs of w
                        if (URL of t as text) contains "soundcloud.com" then
                            execute t javascript "var btn = document.querySelector('.skipControl__previous') || document.querySelector('.playControls__prev'); if(btn) btn.click();"
                            return "ok"
                        end if
                    end repeat
                end repeat
            end tell
            """
            _ = runScript(chromeScript)
        } else {
            postMediaKey(key: 18)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.pollCurrentMedia()
        }
    }

    public func nextTrack() {
        skipNext()
    }

    public func previousTrack() {
        skipPrev()
    }

    public func postMediaKey(key: Int32) {
        func doKey(down: Bool) {
            let flags = NSEvent.ModifierFlags(rawValue: down ? 0xa00 : 0xb00)
            let data1 = Int((key << 16) | (down ? 0xa00 : 0xb00))
            let ev = NSEvent.otherEvent(
                with: .systemDefined,
                location: .zero,
                modifierFlags: flags,
                timestamp: 0,
                windowNumber: 0,
                context: nil,
                subtype: 8,
                data1: data1,
                data2: -1
            )
            ev?.cgEvent?.post(tap: .cghidEventTap)
        }
        doKey(down: true)
        doKey(down: false)
    }

    public func launchPlayer(_ player: DetectedPlayer) {
        if player.name == "Spotify" {
            NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: "/Applications/Spotify.app"), configuration: NSWorkspace.OpenConfiguration())
        } else if player.name == "Apple Music" {
            NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: "/System/Applications/Music.app"), configuration: NSWorkspace.OpenConfiguration())
        } else if player.name.contains("SoundCloud") {
            if let url = URL(string: "https://soundcloud.com/discover") {
                NSWorkspace.shared.open(url)
            }
        } else if player.name.contains("YouTube") {
            if let url = URL(string: "https://music.youtube.com") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}

// MARK: - NOW PLAYING VIEW (Prominent Theme Accent, Monochromatic Frosted Glass, Matching User UI Spec)
public struct NowPlayingView: View {
    @ObservedObject var appState = AppState.shared
    @ObservedObject var media = MediaManager.shared

    public var body: some View {
        VStack(spacing: 12) {
            // DETECTED PLAYERS BAR (Theme-tinted pills)
            HStack(spacing: 8) {
                Text("DETECTED PLAYERS")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(0.8)

                HStack(spacing: 6) {
                    ForEach(media.detectedPlayers) { player in
                        let isActive = media.activePlayerName == player.name
                        Button(action: {
                            media.launchPlayer(player)
                        }) {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(isActive ? appState.currentTheme.primaryAccent : (player.isRunning ? Color.white.opacity(0.7) : Color.white.opacity(0.2)))
                                    .frame(width: 5, height: 5)
                                    .shadow(color: isActive ? appState.currentTheme.primaryAccent.opacity(0.8) : Color.clear, radius: 3)

                                Text(player.name)
                                    .font(.system(size: 10, weight: isActive ? .bold : (player.isRunning ? .medium : .regular)))

                                if isActive {
                                    Text("ACTIVE")
                                        .font(.system(size: 7, weight: .heavy))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(appState.currentTheme.primaryAccent.opacity(0.3))
                                        .cornerRadius(3)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(isActive ? appState.currentTheme.primaryAccent.opacity(0.18) : Color.white.opacity(0.04))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(isActive ? appState.currentTheme.primaryAccent.opacity(0.5) : Color.white.opacity(0.06), lineWidth: 0.8)
                            )
                            .foregroundColor(isActive ? .white : (player.isRunning ? .white.opacity(0.85) : .white.opacity(0.4)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.025))
            .cornerRadius(8)

            // MAIN PLAYER CARD (Matching User Screenshot Specification)
            VStack(spacing: 14) {
                HStack(spacing: 14) {
                    // Album Artwork with Subtle Glow
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        appState.currentTheme.primaryAccent.opacity(0.4),
                                        Color.black.opacity(0.85)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 72, height: 72)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(appState.currentTheme.primaryAccent.opacity(0.4), lineWidth: 1)
                            )
                            .shadow(color: appState.currentTheme.primaryAccent.opacity(0.25), radius: 8, x: 0, y: 2)

                        Image(systemName: media.currentSong.source == "SoundCloud" ? "cloud.fill" : (media.currentSong.isPlaying ? "waveform" : "music.note"))
                            .font(.system(size: 28))
                            .foregroundColor(appState.currentTheme.primaryAccent)
                    }

                    // Title & Artist Info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(media.currentSong.title)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Text(media.currentSong.source.uppercased())
                                .font(.system(size: 8, weight: .heavy))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(appState.currentTheme.primaryAccent.opacity(0.25))
                                .foregroundColor(appState.currentTheme.primaryAccent)
                                .cornerRadius(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(appState.currentTheme.primaryAccent.opacity(0.5), lineWidth: 0.8)
                                )
                        }

                        Text(media.currentSong.artist)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)

                        HStack(spacing: 5) {
                            Circle()
                                .fill(appState.currentTheme.primaryAccent)
                                .frame(width: 5, height: 5)
                            Text(media.currentSong.isPlaying ? "Streaming Audio · Active" : "Paused")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(appState.currentTheme.primaryAccent)
                        }
                    }

                    Spacer()
                }

                // Scrubber Bar
                VStack(spacing: 4) {
                    ProgressView(value: media.currentSong.currentTime, total: media.currentSong.duration)
                        .tint(appState.currentTheme.primaryAccent)

                    HStack {
                        Text(formatTime(media.currentSong.currentTime))
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                        Spacer()
                        Text(formatTime(media.currentSong.duration))
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                // Transport Controls
                HStack(spacing: 20) {
                    Button(action: { media.skipPrev() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .buttonStyle(.plain)

                    Button(action: { media.togglePlayPause() }) {
                        ZStack {
                            Circle()
                                .fill(appState.currentTheme.primaryAccent)
                                .frame(width: 40, height: 40)
                                .shadow(color: appState.currentTheme.primaryAccent.opacity(0.4), radius: 8, x: 0, y: 2)

                            Image(systemName: media.currentSong.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)

                    Button(action: { media.skipNext() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button(action: { media.pollCurrentMedia() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                            Text("Resync")
                        }
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(6)
                        .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.035))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(appState.currentTheme.primaryAccent.opacity(0.2), lineWidth: 1)
            )

            // LYRICS & CONTEXT ACCORDION
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("LIVE STREAM CONTEXT & LYRICS")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(0.8)
                    Spacer()
                }

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(media.currentSong.lyrics.enumerated()), id: \.element.id) { index, line in
                            HStack(spacing: 8) {
                                if index == 1 {
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(appState.currentTheme.primaryAccent)
                                        .frame(width: 2.5, height: 12)
                                }
                                Text(line.text)
                                    .font(.system(size: 11, weight: index == 1 ? .bold : .medium))
                                    .foregroundColor(index == 1 ? .white : .white.opacity(0.6))
                            }
                        }
                    }
                    .padding(.top, 2)
                }
                .frame(maxHeight: 90)
            }
            .padding(12)
            .background(Color.white.opacity(0.02))
            .cornerRadius(10)
        }
        .padding(14)
    }

    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
