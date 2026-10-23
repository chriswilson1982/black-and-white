import AVFoundation

/// The game's sound effects. The original used Pythonista's built-in sounds, which aren't
/// available on iOS, so these are small retro-style tones generated at launch.
enum SoundEffect: CaseIterable {
    case tap, button, win, fail, noWhite, newGame, flip, unlock
    case starBonus, star, starAway, negative, tick, powerup

    fileprivate var notes: [SynthNote] {
        switch self {
        case .tap:
            return [SynthNote(660, 990, 0.07, .square)]
        case .button:
            return [SynthNote(1400, 1400, 0.03, .triangle)]
        case .win:
            return [SynthNote(523, 0.08), SynthNote(659, 0.08), SynthNote(784, 0.08), SynthNote(1047, 0.2)]
        case .fail:
            return [SynthNote(440, 420, 0.14, .saw), SynthNote(330, 310, 0.14, .saw), SynthNote(220, 140, 0.32, .saw)]
        case .noWhite:
            let frequencies: [Double] = [523, 659, 784, 1047, 1319, 1568]
            return frequencies.map { SynthNote($0, 0.06, .square) }
        case .newGame:
            return [SynthNote(220, 880, 0.25, .square)]
        case .flip:
            return [SynthNote(400, 1200, 0.12, .triangle), SynthNote(1200, 400, 0.12, .triangle)]
        case .unlock:
            return [SynthNote(587, 0.07, .sine), SynthNote(784, 0.07, .sine), SynthNote(1175, 0.14, .sine)]
        case .starBonus:
            return [SynthNote(1047, 0.07, .sine), SynthNote(1319, 0.07, .sine),
                    SynthNote(1568, 0.07, .sine), SynthNote(2093, 0.28, .sine)]
        case .star:
            return [SynthNote(500, 2000, 0.3, .sine)]
        case .starAway:
            return [SynthNote(1500, 300, 0.35, .sine)]
        case .negative:
            return [SynthNote(600, 200, 0.35, .saw)]
        case .tick:
            return [SynthNote(1000, 0.05, .sine)]
        case .powerup:
            return [SynthNote(784, 0.07, .square), SynthNote(1175, 0.12, .square)]
        }
    }
}

fileprivate enum Wave { case sine, square, triangle, saw }

fileprivate struct SynthNote {
    let from: Double
    let to: Double
    let duration: Double
    let wave: Wave

    init(_ from: Double, _ to: Double, _ duration: Double, _ wave: Wave) {
        self.from = from
        self.to = to
        self.duration = duration
        self.wave = wave
    }

    init(_ frequency: Double, _ duration: Double, _ wave: Wave = .triangle) {
        self.init(frequency, frequency, duration, wave)
    }
}

final class SoundEngine {
    static let shared = SoundEngine()

    var enabled = true

    private let engine = AVAudioEngine()
    private let format: AVAudioFormat
    private var players: [AVAudioPlayerNode] = []
    private var buffers: [SoundEffect: AVAudioPCMBuffer] = [:]
    private var nextPlayer = 0
    private var isConfigured = false

    private init() {
        format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    }

    func play(_ effect: SoundEffect) {
        guard enabled else { return }
        configureIfNeeded()
        if !engine.isRunning {
            do { try engine.start() } catch { return }
        }
        guard let buffer = buffers[effect], !players.isEmpty else { return }
        let player = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % players.count
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        player.play()
    }

    private func configureIfNeeded() {
        guard !isConfigured else { return }
        isConfigured = true
        // Ambient: respects the silent switch and mixes with the player's music.
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        try? AVAudioSession.sharedInstance().setActive(true)

        for _ in 0..<8 {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            players.append(player)
        }
        engine.mainMixerNode.outputVolume = 0.35
        for effect in SoundEffect.allCases {
            buffers[effect] = render(effect.notes)
        }
        engine.prepare()
    }

    private func render(_ notes: [SynthNote]) -> AVAudioPCMBuffer? {
        let rate = format.sampleRate
        let total = notes.reduce(0) { $0 + Int($1.duration * rate) }
        guard total > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(total)),
              let samples = buffer.floatChannelData?[0]
        else { return nil }
        buffer.frameLength = AVAudioFrameCount(total)

        var offset = 0
        var phase = 0.0
        for note in notes {
            let count = Int(note.duration * rate)
            let attack = min(0.004 * rate, Double(count) / 4)
            for i in 0..<count {
                let t = Double(i) / Double(max(count - 1, 1))
                // Exponential glide between the two frequencies.
                let frequency = note.from * pow(note.to / note.from, t)
                phase += frequency / rate
                phase -= floor(phase)

                let raw: Double
                switch note.wave {
                case .sine: raw = sin(2 * .pi * phase)
                case .square: raw = (phase < 0.5 ? 1 : -1) * 0.45
                case .triangle: raw = 4 * abs(phase - 0.5) - 1
                case .saw: raw = (2 * phase - 1) * 0.5
                }
                // Short fade in, then decay, so notes don't click.
                let envelope = min(1, Double(i) / max(attack, 1)) * pow(1 - t, 1.5)
                samples[offset + i] = Float(raw * envelope * 0.6)
            }
            offset += count
        }
        return buffer
    }
}
