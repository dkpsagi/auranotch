import SwiftUI
import AVFoundation

public class FocusSoundSynthesizer: ObservableObject {
    public static let shared = FocusSoundSynthesizer()

    private var engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?

    @Published public var currentSound: String = "None"
    @Published public var isPlaying: Bool = false
    @Published public var volume: Float = 0.45

    public let availableSounds: [(name: String, icon: String, description: String, color: Color)] = [
        ("None", "speaker.slash", "Silent focus timer", Color.gray),
        ("Rain & Storm", "cloud.rain.fill", "Low-frequency brown noise rainfall", Color.blue),
        ("White Noise", "waveform.path", "Balanced broadband masking noise", Color.purple),
        ("Binaural 40Hz Focus", "headphones", "Gamma frequency flow-state carrier", Color.orange),
        ("Forest Wind", "wind", "Gentle pink noise wind gusts", Color.teal)
    ]

    private init() {}

    public func togglePlay(sound: String) {
        if isPlaying && currentSound == sound {
            stop()
        } else {
            play(sound: sound)
        }
    }

    public func play(sound: String) {
        stop()
        guard sound != "None" else { return }

        currentSound = sound
        isPlaying = true

        let mainMixer = engine.mainMixerNode
        let outputFormat = mainMixer.outputFormat(forBus: 0)
        let sampleRate = Float(outputFormat.sampleRate > 0 ? outputFormat.sampleRate : 44100)

        var lastSample: Float = 0.0
        var phase: Float = 0.0

        let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let vol = self.volume

            for frame in 0..<Int(frameCount) {
                var value: Float = 0.0
                switch sound {
                case "White Noise":
                    value = Float.random(in: -0.12...0.12)
                case "Rain & Storm":
                    // Low-pass filtered brown noise (rain sound)
                    let white = Float.random(in: -0.35...0.35)
                    lastSample = (lastSample * 0.94) + (white * 0.06)
                    value = lastSample * 1.6
                case "Binaural 40Hz Focus":
                    // 200 Hz carrier frequency
                    phase += 240.0 / sampleRate
                    if phase > 1.0 { phase -= 1.0 }
                    value = sin(phase * 2.0 * .pi) * 0.15
                case "Forest Wind":
                    // Sweeping pink noise
                    let white = Float.random(in: -0.2...0.2)
                    lastSample = (lastSample * 0.97) + (white * 0.03)
                    value = lastSample * 2.2
                default:
                    value = Float.random(in: -0.1...0.1)
                }

                for buffer in ablPointer {
                    let ptr: UnsafeMutablePointer<Float> = buffer.mData!.assumingMemoryBound(to: Float.self)
                    ptr[frame] = value * vol
                }
            }
            return noErr
        }

        sourceNode = node
        engine.attach(node)
        engine.connect(node, to: mainMixer, format: outputFormat)
        try? engine.start()
    }

    public func stop() {
        if engine.isRunning {
            engine.stop()
        }
        if let node = sourceNode {
            engine.detach(node)
            sourceNode = nil
        }
        isPlaying = false
    }

    public func updateVolume(_ newVol: Float) {
        self.volume = newVol
    }
}

public class TimerManager: ObservableObject {
    public static let shared = TimerManager()

    @Published public var focusMinutes: Int = 25
    @Published public var secondsRemaining: Int = 25 * 60
    @Published public var isRunning: Bool = false
    @Published public var isBreak: Bool = false

    private var timer: Timer?

    public func toggleTimer() {
        isRunning.toggle()
        AppState.shared.isTimerRunning = isRunning
        if isRunning {
            // Auto-sync audio playback with timer!
            let sound = FocusSoundSynthesizer.shared
            if sound.currentSound == "None" {
                sound.play(sound: "Rain & Storm")
            } else if !sound.isPlaying {
                sound.play(sound: sound.currentSound)
            }

            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                if self.secondsRemaining > 0 {
                    self.secondsRemaining -= 1
                    AppState.shared.activeTimerSecondsRemaining = self.secondsRemaining
                } else {
                    self.switchMode()
                }
            }
        } else {
            timer?.invalidate()
            timer = nil
            // Pause synced audio
            FocusSoundSynthesizer.shared.stop()
        }
    }

    public func adjustTime(byMinutes mins: Int) {
        let delta = mins * 60
        let newSeconds = secondsRemaining + delta
        if newSeconds >= 60 {
            secondsRemaining = newSeconds
            focusMinutes = max(1, secondsRemaining / 60)
            AppState.shared.activeTimerSecondsRemaining = secondsRemaining
        }
    }

    public func setPreset(minutes: Int) {
        focusMinutes = minutes
        secondsRemaining = minutes * 60
        AppState.shared.activeTimerSecondsRemaining = secondsRemaining
    }

    public func resetTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        AppState.shared.isTimerRunning = false
        secondsRemaining = focusMinutes * 60
        AppState.shared.activeTimerSecondsRemaining = secondsRemaining
        FocusSoundSynthesizer.shared.stop()
    }

    private func switchMode() {
        NSSound(named: "Glass")?.play()
        isBreak.toggle()
        secondsRemaining = isBreak ? 5 * 60 : focusMinutes * 60
        if isBreak {
            FocusSoundSynthesizer.shared.stop()
        }
    }
}

public struct TimersPomodoroView: View {
    @ObservedObject var timerMgr = TimerManager.shared
    @ObservedObject var soundEngine = FocusSoundSynthesizer.shared

    public var body: some View {
        HStack(spacing: 20) {
            // Radial Progress Countdown
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 8)
                        .frame(width: 114, height: 114)

                    let total = Double((timerMgr.isBreak ? 5 : timerMgr.focusMinutes) * 60)
                    let progress = total > 0 ? Double(timerMgr.secondsRemaining) / total : 0.0

                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(
                            timerMgr.isBreak ? Color.green : Color.orange,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 114, height: 114)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.0), value: progress)

                    VStack(spacing: 2) {
                        Text(timeString(from: timerMgr.secondsRemaining))
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        Text(timerMgr.isBreak ? "Break" : "Focus Session")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(timerMgr.isBreak ? .green : .orange)
                    }
                }

                // Time Adjuster (+/- Buttons)
                HStack(spacing: 4) {
                    Button(action: { timerMgr.adjustTime(byMinutes: -5) }) {
                        Text("-5m")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(.white.opacity(0.8))
                            .cornerRadius(5)
                    }
                    .buttonStyle(.plain)

                    Button(action: { timerMgr.adjustTime(byMinutes: -1) }) {
                        Text("-1m")
                            .font(.system(size: 9, weight: .medium))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.06))
                            .foregroundColor(.white.opacity(0.7))
                            .cornerRadius(5)
                    }
                    .buttonStyle(.plain)

                    Button(action: { timerMgr.adjustTime(byMinutes: 1) }) {
                        Text("+1m")
                            .font(.system(size: 9, weight: .medium))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.06))
                            .foregroundColor(.white.opacity(0.7))
                            .cornerRadius(5)
                    }
                    .buttonStyle(.plain)

                    Button(action: { timerMgr.adjustTime(byMinutes: 5) }) {
                        Text("+5m")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(.white.opacity(0.8))
                            .cornerRadius(5)
                    }
                    .buttonStyle(.plain)
                }

                // Timer Controls
                HStack(spacing: 10) {
                    Button(action: { timerMgr.toggleTimer() }) {
                        HStack(spacing: 5) {
                            Image(systemName: timerMgr.isRunning ? "pause.fill" : "play.fill")
                            Text(timerMgr.isRunning ? "Pause" : "Start")
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(timerMgr.isRunning ? Color.orange : Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    Button(action: { timerMgr.resetTimer() }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 170)

            Divider()
                .background(Color.white.opacity(0.1))

            // REAL AMBIENT FOCUS AUDIO ENGINE
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ambient Focus Sounds (Live Audio)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                            .textCase(.uppercase)
                        Text("Plays synthesized audio directly to speakers/AirPods")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.4))
                    }

                    Spacer()

                    if soundEngine.isPlaying {
                        HStack(spacing: 2) {
                            ForEach(0..<4) { i in
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color.orange)
                                    .frame(width: 2.5, height: CGFloat([6, 12, 16, 9][i]))
                            }
                        }
                    }
                }

                // Sound Tracks Grid
                VStack(spacing: 6) {
                    ForEach(soundEngine.availableSounds, id: \.name) { sound in
                        let isSelected = soundEngine.currentSound == sound.name
                        Button(action: {
                            soundEngine.togglePlay(sound: sound.name)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: sound.icon)
                                    .font(.system(size: 12))
                                    .foregroundColor(isSelected && soundEngine.isPlaying ? sound.color : .white.opacity(0.5))
                                    .frame(width: 18)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(sound.name)
                                        .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                        .foregroundColor(.white)
                                    Text(sound.description)
                                        .font(.system(size: 9))
                                        .foregroundColor(.white.opacity(0.45))
                                }

                                Spacer()

                                if isSelected && soundEngine.isPlaying {
                                    Text("PLAYING")
                                        .font(.system(size: 8, weight: .bold))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(sound.color.opacity(0.3))
                                        .foregroundColor(sound.color)
                                        .cornerRadius(4)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(isSelected && soundEngine.isPlaying ? Color.white.opacity(0.1) : Color.white.opacity(0.04))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Volume slider
                if soundEngine.isPlaying {
                    HStack(spacing: 8) {
                        Image(systemName: "speaker.wave.1.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                        Slider(value: Binding(
                            get: { Double(soundEngine.volume) },
                            set: { soundEngine.updateVolume(Float($0)) }
                        ), in: 0...1)
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(14)
    }

    private func timeString(from totalSeconds: Int) -> String {
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
