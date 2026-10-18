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
    public init() {}
    public var body: some View {
        ADHDToolsView()
    }
}
