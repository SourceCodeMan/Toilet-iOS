import Foundation

/// One flush, described as pure functions of elapsed time.
///
/// The drawing reads these functions every frame inside a `TimelineView`, and the
/// engine schedules the sound, the haptics and the payoff line against the same
/// numbers, so the picture and the noise can't drift apart.
enum FlushTimeline {

    /// How long a flush takes, start to settled, in seconds.
    static let duration: Double = 3.6

    /// Water level in the bowl when nothing is happening. 0 = empty, 1 = brimming.
    static let restingLevel: Double = 0.52

    /// How far the handle is pushed down, 0 = resting, 1 = bottomed out.
    static func handlePush(at t: Double) -> Double {
        // Slam down, hang there for a beat, then let the spring take it back.
        segment(t, 0, 0.07) - segment(t, 0.24, 0.58)
    }

    static func level(at t: Double) -> Double {
        var level = restingLevel
        level += (0.95 - restingLevel) * segment(t, 0.10, 0.55)  // the surge that always looks like an overflow
        level -= 0.90 * segment(t, 0.55, 1.35)                   // ...and then it all goes
        level += (restingLevel - 0.05) * segment(t, 1.60, 3.30)  // tank refills
        level += 0.014 * sin(t * 17) * turbulence(at: t)         // chop on the surface
        return min(max(level, 0), 1)
    }

    /// Total rotation of the water since the flush began, in degrees.
    ///
    /// Piecewise so the velocity is continuous: it winds up over `windUp`, then
    /// eases off to a stop. Integrated by hand rather than sampled, because the
    /// view can be asked for any `t` at any time.
    static func spin(at t: Double) -> Double {
        let peak = 1400.0      // degrees per second at full churn
        let windUp = 0.40
        let stop = 3.20
        if t <= 0 { return 0 }
        if t < windUp { return peak * t * t / (2 * windUp) }
        let windUpTotal = peak * windUp / 2
        guard t < stop else { return windUpTotal + peak * (stop - windUp) / 3 }
        let u = (t - windUp) / (stop - windUp)
        return windUpTotal + peak * (stop - windUp) * (1 - pow(1 - u, 3)) / 3
    }

    /// How hard the water is churning, 0...1. Drives foam, bubbles and the vortex.
    static func turbulence(at t: Double) -> Double {
        min(max(segment(t, 0.05, 0.35) - segment(t, 1.90, 3.10), 0), 1)
    }

    /// Sideways shake of the whole fixture, in points.
    static func rumble(at t: Double) -> Double {
        turbulence(at: t) * (sin(t * 41.3) * 0.65 + sin(t * 67.7) * 0.35) * 1.7
    }

    // MARK: - Easing

    private static func segment(_ t: Double, _ start: Double, _ end: Double) -> Double {
        guard end > start else { return t < start ? 0 : 1 }
        let x = min(max((t - start) / (end - start), 0), 1)
        return x * x * (3 - 2 * x)
    }
}
