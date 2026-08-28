import CoreHaptics
import UIKit

/// The flush you can feel: a clunk from the handle, then a long rumble that
/// fades out as the tank refills. Falls back to a plain impact on hardware
/// without a Taptic Engine, and does nothing at all where there is none.
final class Haptics {

    static let shared = Haptics()

    private var engine: CHHapticEngine?
    private var isSupported: Bool { CHHapticEngine.capabilitiesForHardware().supportsHaptics }

    func prepare() {
        guard isSupported, engine == nil else { return }
        do {
            let newEngine = try CHHapticEngine()
            newEngine.isAutoShutdownEnabled = true
            newEngine.resetHandler = { [weak self] in try? self?.engine?.start() }
            try newEngine.start()
            engine = newEngine
        } catch {
            engine = nil
        }
    }

    /// The lever catching, the instant you press it.
    func tick() {
        guard isSupported else {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.6)
            return
        }
        play(events: [
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.42),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.95)
            ], relativeTime: 0)
        ], curves: [])
    }

    /// A short knock, for when you mash the handle mid-flush.
    func thud() {
        guard isSupported else { return }
        play(events: [
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.55),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
            ], relativeTime: 0)
        ], curves: [])
    }

    /// `scale` stretches the buzz with the fixture, the same way the noise and the
    /// picture stretch. It is the fixture's scale rather than the graded one, so the
    /// golden taps stay locked to the golden notes, which are cached per fixture.
    func flush(golden: Bool, scale: Double = 1) {
        guard isSupported else {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            return
        }

        var events: [CHHapticEvent] = [
            // The lever bottoming out.
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.85)
            ], relativeTime: 0),
            // The water itself.
            CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.75),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
            ], relativeTime: 0.10 * scale, duration: 2.9 * scale)
        ]

        if golden {
            for step in 0..<4 {
                events.append(CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 1)
                ], relativeTime: 2.15 * scale + Double(step) * 0.13))
            }
        }

        let swell = CHHapticParameterCurve(parameterID: .hapticIntensityControl, controlPoints: [
            CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 0.2),
            CHHapticParameterCurve.ControlPoint(relativeTime: 0.35 * scale, value: 1),
            CHHapticParameterCurve.ControlPoint(relativeTime: 1.5 * scale, value: 0.7),
            CHHapticParameterCurve.ControlPoint(relativeTime: 2.9 * scale, value: 0.05)
        ], relativeTime: 0.10 * scale)

        play(events: events, curves: [swell])
    }

    private func play(events: [CHHapticEvent], curves: [CHHapticParameterCurve]) {
        prepare()
        guard let engine else { return }
        do {
            let pattern = try CHHapticPattern(events: events, parameterCurves: curves)
            let player = try engine.makePlayer(with: pattern)
            try engine.start()
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // A missed buzz is not worth bothering anyone about.
        }
    }
}
