import Foundation

/// One flush, described as pure functions of elapsed time.
///
/// The drawing reads these functions every frame inside a `TimelineView`, and the
/// engine schedules the sound, the haptics and the payoff line against the same
/// numbers, so the picture and the noise can't drift apart.
///
/// The numbers that give a flush its character now live in `FlushProfile`, so a
/// different fixture can surge higher or swirl longer without this file changing.
/// The shape of the curves is still here; only the magnitudes travel.
enum FlushTimeline {

    /// How far the handle is pushed down, 0 = resting, 1 = bottomed out.
    ///
    /// The handle is the same lever on every fixture, so this one takes no profile.
    /// It is also over inside 0.6s, which is well inside the shortest flush there is.
    static func handlePush(at t: Double) -> Double {
        // Slam down, hang there for a beat, then let the spring take it back.
        segment(t, 0, 0.07) - segment(t, 0.24, 0.58)
    }

    /// What is left in the bowl at the bottom of the drain, before the tank refills.
    ///
    /// The floor of the basin rather than anything a fixture chooses, so it stays a
    /// constant — but the drain and the refill are both measured against it rather
    /// than against a hard-coded depth, which is what makes a flush finish at exactly
    /// the level it started from whatever the fixture's surge and resting level are.
    private static let drained = 0.05

    static func level(at t: Double, _ p: FlushProfile) -> Double {
        let s = p.timeScale
        var level = p.restingLevel
        level += (p.surgePeak - p.restingLevel) * segment(t, 0.10 * s, 0.55 * s)  // the surge that always looks like an overflow
        level -= (p.surgePeak - Self.drained) * segment(t, 0.55 * s, 1.35 * s)    // ...and then it all goes
        level += (p.restingLevel - Self.drained) * segment(t, 1.60 * s, 3.30 * s) // tank refills
        level += p.chop * sin(t * 17) * turbulence(at: t, p)                      // chop on the surface
        return min(max(level, 0), 1)
    }

    /// Total rotation of the water since the flush began, in degrees.
    ///
    /// Piecewise so the velocity is continuous: it winds up over `windUp`, then
    /// eases off to a stop. Integrated by hand rather than sampled, because the
    /// view can be asked for any `t` at any time.
    static func spin(at t: Double, _ p: FlushProfile) -> Double {
        let peak = p.spinPeak   // degrees per second at full churn
        let windUp = 0.40 * p.timeScale
        let stop = 3.20 * p.timeScale
        if t <= 0 { return 0 }
        if t < windUp { return peak * t * t / (2 * windUp) }
        let windUpTotal = peak * windUp / 2
        guard t < stop else { return windUpTotal + peak * (stop - windUp) / 3 }
        let u = (t - windUp) / (stop - windUp)
        return windUpTotal + peak * (stop - windUp) * (1 - pow(1 - u, 3)) / 3
    }

    /// How hard the water is churning, 0...1. Drives foam, bubbles and the vortex.
    ///
    /// Scaled with the flush like everything else, so a short fixture — or a weak
    /// pull, which shortens one — settles rather than being cut off mid-churn.
    static func turbulence(at t: Double, _ p: FlushProfile) -> Double {
        let s = p.timeScale
        return min(max(segment(t, 0.05 * s, 0.35 * s) - segment(t, 1.90 * s, 3.10 * s), 0), 1)
    }

    /// Sideways shake of the whole fixture, in points.
    static func rumble(at t: Double, _ p: FlushProfile) -> Double {
        turbulence(at: t, p) * (sin(t * 41.3) * 0.65 + sin(t * 67.7) * 0.35) * p.rumbleScale
    }

    // MARK: - Easing

    private static func segment(_ t: Double, _ start: Double, _ end: Double) -> Double {
        guard end > start else { return t < start ? 0 : 1 }
        let x = min(max((t - start) / (end - start), 0), 1)
        return x * x * (3 - 2 * x)
    }
}
