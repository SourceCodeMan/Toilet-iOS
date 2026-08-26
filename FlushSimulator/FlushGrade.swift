import Foundation

/// How well the handle was pulled.
///
/// Real cisterns want the lever held down for a moment — let go early and you get a
/// half flush, lean on it and you are just wasting water. That is the whole skill:
/// hold, and let go inside the window.
enum FlushGrade: Equatable {

    /// Released before the cistern really got going.
    case weak

    /// Held about right.
    case good

    /// Released inside the window.
    case perfect

    /// Leaned on it. Counts, but nobody is impressed.
    case overheld

    // MARK: - The window

    /// Below this, the cistern has barely opened.
    static let weakUntil: Double = 0.34

    /// The window you are aiming for, in seconds of hold.
    static let perfectFrom: Double = 0.55
    static let perfectUntil: Double = 0.88

    /// Past here you are just holding a lever.
    static let overheldFrom: Double = 1.35

    /// The full travel drawn on the meter.
    static let meterSpan: Double = 1.5

    static func grade(forHold seconds: Double) -> FlushGrade {
        switch seconds {
        case ..<weakUntil:                    return .weak
        case perfectFrom..<perfectUntil:      return .perfect
        case overheldFrom...:                 return .overheld
        default:                              return .good
        }
    }

    // MARK: - Consequences

    /// Does this keep a streak alive?
    var keepsStreak: Bool { self == .perfect }

    /// Does this break one that is already running?
    var breaksStreak: Bool { self == .weak || self == .overheld }

    var label: String {
        switch self {
        case .weak:     return "Half flush"
        case .good:     return "Good flush"
        case .perfect:  return "Perfect flush"
        case .overheld: return "Held too long"
        }
    }

    /// The flush this grade earns you.
    ///
    /// A weak pull barely disturbs the bowl; a perfect one surges higher and spins
    /// harder than the fixture's own numbers. The fixture still sets the character —
    /// this only scales it.
    func apply(to p: FlushProfile) -> FlushProfile {
        var out = p
        switch self {
        case .weak:
            out.surgePeak = p.restingLevel + (p.surgePeak - p.restingLevel) * 0.35
            out.spinPeak = p.spinPeak * 0.45
            out.duration = p.duration * 0.72
            out.rumbleScale = p.rumbleScale * 0.5
        case .good:
            break
        case .perfect:
            out.surgePeak = min(p.surgePeak * 1.06, 0.995)
            out.spinPeak = p.spinPeak * 1.22
            out.rumbleScale = p.rumbleScale * 1.15
        case .overheld:
            // All the noise, none of the grace.
            out.spinPeak = p.spinPeak * 0.85
            out.duration = p.duration * 1.15
            out.rumbleScale = p.rumbleScale * 1.3
        }
        return out
    }
}
