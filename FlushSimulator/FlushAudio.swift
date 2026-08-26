import AVFoundation

/// The flush noise, built from scratch at launch.
///
/// A recording would mean shipping a binary blob nobody can read, so the sound is
/// synthesised instead: a clunk off the handle, a roar of band-passed noise whose
/// centre frequency sweeps down as the bowl empties, a wobbling gurgle, and the
/// long hiss of the tank refilling behind it.
///
/// Buffers are rendered once on a background queue and played back whole, which
/// keeps every bit of this arithmetic well away from the audio render thread.
final class FlushAudio {

    static let shared = FlushAudio()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate: Double = 44_100
    private let queue = DispatchQueue(label: "com.flushsimulator.audio", qos: .userInitiated)

    private var ordinary: [AVAudioPCMBuffer] = []
    private var golden: AVAudioPCMBuffer?
    private var isPreparing = false
    private var isConfigured = false

    /// Which voice is currently sitting in the buffers, or nil if none is.
    ///
    /// Doubles as the "ready to play" flag: it is only set once rendering has
    /// actually produced buffers, so a failed render retries rather than leaving
    /// the app permanently silent. Fixtures are rendered on demand rather than all
    /// at once — a take is ~767KB, and there are four per voice.
    private var renderedVoice: FlushProfile?

    private static let muteKey = "flushMuted"

    var isMuted: Bool {
        get { UserDefaults.standard.bool(forKey: Self.muteKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.muteKey)
            if newValue { queue.async { [self] in player.stop() } }
        }
    }

    /// Renders one fixture's voice and wires up the engine. Safe to call more than
    /// once, and cheap when the voice asked for is already loaded.
    func prepare(_ voice: FlushProfile) {
        queue.async { [self] in
            guard renderedVoice != voice, !isPreparing else { return }
            isPreparing = true
            defer { isPreparing = false }

            guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
            if !isConfigured {
                engine.attach(player)
                engine.connect(player, to: engine.mainMixerNode, format: format)
                isConfigured = true
            }

            // Three takes so the same noise doesn't repeat back to back.
            let seeds: [UInt64] = [11, 4_242, 90_210]
            let takes = seeds.compactMap { render(format: format, seed: $0, golden: false, voice) }
            let rare = render(format: format, seed: 777, golden: true, voice)

            guard !takes.isEmpty, rare != nil else { return }
            ordinary = takes
            golden = rare
            renderedVoice = voice
        }
    }

    func play(golden playGolden: Bool, voice: FlushProfile) {
        guard !isMuted else { return }
        // Keep preparation and this request ordered on the serial queue. This makes
        // a pull immediately after launch — or immediately after swapping fixtures —
        // play as soon as rendering ends.
        prepare(voice)
        queue.async { [self] in
            guard renderedVoice == voice else { return }
            playPrepared(golden: playGolden)
        }
    }

    func stop() {
        queue.async { [self] in player.stop() }
    }

    private func playPrepared(golden playGolden: Bool) {
        guard let buffer = playGolden ? golden : ordinary.randomElement() else { return }

        // .playback so the flush is audible even with the ringer silenced; .mixWithOthers
        // so it still leaves whatever music you had going alone.
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)

        if !engine.isRunning {
            do { try engine.start() } catch { return }
        }

        player.stop()
        player.scheduleBuffer(buffer, at: nil, options: [.interrupts], completionHandler: nil)
        player.play()
    }

    // MARK: - Synthesis

    private func render(format: AVAudioFormat, seed: UInt64, golden: Bool, _ p: FlushProfile) -> AVAudioPCMBuffer? {
        let seconds = 4.35
        let frameCount = AVAudioFrameCount(seconds * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channel = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frameCount

        var noise = Noise(seed: seed)
        var roar = Resonator(sampleRate: sampleRate)
        var body = Resonator(sampleRate: sampleRate)
        var gurgle = Resonator(sampleRate: sampleRate)
        var hiss = Resonator(sampleRate: sampleRate)

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let n = noise.next()
            var sample = 0.0

            // The handle bottoming out.
            if t < 0.22 {
                sample += sin(2 * .pi * p.clunkFrequency * t) * exp(-t * 32) * 0.45
                sample += n * exp(-t * 85) * 0.30
            }

            // The main event: bright at first, dropping as the bowl empties.
            let roarLevel = envelope(t, from: 0.08, peak: 0.45, hold: 1.85, until: 2.85)
            if roarLevel > 0 {
                let sweep = p.roarFrom - (p.roarFrom - p.roarTo) * clamp((t - 0.18) / 1.7)
                roar.tune(to: sweep, q: 1.15)
                body.tune(to: p.bodyFrequency, q: 0.8)
                sample += (roar.bandPass(n) * 0.55 + body.lowPass(n) * 0.85) * roarLevel
            }

            // The uneven glugging underneath it.
            let gurgleLevel = envelope(t, from: 0.45, peak: 0.85, hold: 1.95, until: 2.55)
            if gurgleLevel > 0 {
                gurgle.tune(to: p.gurgleCentre + p.gurgleSwing * sin(2 * .pi * 1.7 * t), q: 5)
                let wobble = 0.55 + 0.45 * sin(2 * .pi * (5.5 + 2.5 * sin(2 * .pi * 0.7 * t)) * t)
                sample += gurgle.bandPass(n) * gurgleLevel * wobble * 0.85
            }

            // The tank filling back up, rising in pitch as it gets full.
            let hissLevel = envelope(t, from: 2.00, peak: 2.35, hold: 3.30, until: 4.15)
            if hissLevel > 0 {
                hiss.tune(to: p.hissFrom + (p.hissTo - p.hissFrom) * clamp((t - 2.2) / 1.6), q: 0.9)
                sample += hiss.bandPass(n) * hissLevel * 0.30
            }

            // The float valve shutting off.
            if t > 4.10 {
                let since = t - 4.10
                sample += sin(2 * .pi * p.valveFrequency * since) * exp(-since * 38) * 0.32
            }

            // A little fanfare, for the rare ones.
            if golden {
                for (step, frequency) in Self.fanfare.enumerated() {
                    let start = 2.15 + Double(step) * 0.13
                    guard t > start else { continue }
                    let since = t - start
                    sample += sin(2 * .pi * frequency * since) * exp(-since * 3.2) * 0.15
                }
            }

            // Soft clip, so nothing ever spits.
            channel[frame] = Float(tanh(sample * 0.95) * 0.55)
        }

        return buffer
    }

    /// C, E, G, C. Hoisted out of the render loop, which runs 190,000 times a take.
    private static let fanfare: [Double] = [523.25, 659.25, 783.99, 1_046.50]

    private func clamp(_ x: Double) -> Double { min(max(x, 0), 1) }

    /// Rise, hold, fall — with smoothed corners so nothing clicks.
    private func envelope(_ t: Double, from start: Double, peak: Double, hold: Double, until end: Double) -> Double {
        guard t > start, t < end else { return 0 }
        if t < peak { return smooth((t - start) / max(peak - start, 0.001)) }
        if t < hold { return 1 }
        return smooth(1 - (t - hold) / max(end - hold, 0.001))
    }

    private func smooth(_ x: Double) -> Double {
        let c = min(max(x, 0), 1)
        return c * c * (3 - 2 * c)
    }
}

/// A two-pole state-variable filter. Turns flat noise into something that sounds
/// like it is coming out of a pipe.
private struct Resonator {
    private let sampleRate: Double
    private var low = 0.0
    private var band = 0.0
    private var f = 0.1
    private var damping = 1.0

    init(sampleRate: Double) { self.sampleRate = sampleRate }

    mutating func tune(to frequency: Double, q: Double) {
        let bounded = min(max(frequency, 20), sampleRate / 6)
        f = 2 * sin(.pi * bounded / sampleRate)
        damping = 1 / max(q, 0.5)
    }

    mutating func bandPass(_ input: Double) -> Double {
        step(input)
        return band
    }

    mutating func lowPass(_ input: Double) -> Double {
        step(input)
        return low
    }

    private mutating func step(_ input: Double) {
        let high = input - low - damping * band
        band = min(max(band + f * high, -4), 4)
        low = min(max(low + f * band, -4), 4)
    }
}

/// A small, fast, repeatable noise source. Repeatable matters: the same seed gives
/// the same flush every launch, so a take that sounds good stays sounding good.
private struct Noise {
    private var state: UInt64

    init(seed: UInt64) { state = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407 }

    mutating func next() -> Double {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        let bits = UInt32(truncatingIfNeeded: state >> 33)
        return Double(bits) / Double(UInt32.max) * 2 - 1
    }
}
