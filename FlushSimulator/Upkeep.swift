import Foundation

/// Grime, paper, and the odds of blocking the thing.
///
/// These three are one system, not three. Flushing dirties the bowl; a dirty bowl
/// blocks more easily; paper is the thing worth having and the thing that blocks it.
/// Every number that balances that loop lives here so it can be tuned in one place.
enum Upkeep {

    // MARK: - Grime

    /// How much filth one flush leaves behind. Forty flushes takes a clean bowl to
    /// a filthy one.
    static let grimePerFlush: Double = 1.0 / 40.0

    /// At or below this, the bowl counts as clean and the golden odds improve.
    static let cleanBelow: Double = 0.20

    /// At or above this, the app starts saying something about it — and gold
    /// becomes scarce.
    static let grimyAbove: Double = 0.65

    /// At or above this the bowl is a health hazard: gold is impossible and a flush
    /// costs you your streak. Neglect has to bite, or the wand is decoration.
    static let filthyAbove: Double = 0.88

    /// What a grimy-but-not-filthy bowl does to the golden odds.
    static let grimyGoldPenalty: Double = 0.20

    // MARK: - Paper

    /// Squares you can put in. Zero is allowed, and pointless.
    static let paperRange = 0...5

    /// Where the app starts you.
    static let defaultPaper = 2

    /// What an uncut sheet counts as. The bowl keeps drawing off the roll for the
    /// whole flush, so it is far past anything you could have hung there on purpose
    /// — which is the point: forgetting to tear is not a small mistake.
    static let runawayPaper = 12

    /// Score multiplier for a flush, by squares used.
    ///
    /// Rises fast then flattens, so there is a real reason to push past two and a
    /// diminishing one to go all the way to five. Using none is deliberately worse
    /// than using one: a flush with nothing in it is not worth anything.
    static func multiplier(forPaper squares: Int) -> Double {
        switch squares {
        case ..<1:  return 0.5
        case 1:     return 1.0
        case 2:     return 1.4
        case 3:     return 1.8
        case 4:     return 2.1
        default:    return 2.3
        }
    }

    /// What a golden flush is worth over an ordinary one.
    static let goldenBonus: Double = 3.0

    /// What one flush is worth on the board.
    ///
    /// The multiplier above is the whole reason to risk more paper, so it has to
    /// land somewhere the player can see. Without this, paper is pure downside:
    /// more grime and more clogs for nothing.
    static func points(paper: Int, golden: Bool) -> Int {
        let base = 100.0 * multiplier(forPaper: paper)
        return Int((golden ? base * goldenBonus : base).rounded())
    }

    // MARK: - The tank

    /// Flushes in one tank. The whole reason a session has a shape: without a
    /// bound, nothing you do is a decision, because there is always another flush.
    static let runLength = 20

    /// Scrubbing runs clean water through, so it costs the tank the same as a flush.
    /// This is what gives grime a price — a free wand makes neglect free.
    static let wandCost = 1

    // MARK: - Gold

    /// One flush in this many is golden with a filthy bowl and no streak going.
    static let goldenBaseOdds = 34

    /// A spotless bowl is worth this much more.
    static let goldenCleanBonus: Double = 1.30

    /// Each perfect pull in the current run adds this much, up to `goldenStreakCap`
    /// pulls. Capped because an unbroken run used to drive the odds into the floor
    /// and gold stopped feeling like anything.
    static let goldenStreakStep: Double = 0.14
    static let goldenStreakCap = 6

    /// However well you play, gold never gets more common than one in this many.
    static let goldenBestOdds = 12

    /// The chance the next flush is golden, 0...1.
    static func goldenChance(streak: Int, grime: Double) -> Double {
        // A filthy bowl does not produce gold. At all.
        guard grime < filthyAbove else { return 0 }

        var p = 1.0 / Double(goldenBaseOdds)
        if grime <= cleanBelow { p *= goldenCleanBonus }
        if grime >= grimyAbove { p *= grimyGoldPenalty }
        p *= 1 + Double(min(streak, goldenStreakCap)) * goldenStreakStep
        return min(p, 1.0 / Double(goldenBestOdds))
    }

    // MARK: - Clogging

    /// The chance this flush blocks, 0...1.
    ///
    /// Paper is the main driver and grime multiplies it, so neglect and greed
    /// compound rather than merely adding up. A perfect pull pushes more water
    /// through and forgives some of it.
    static func clogChance(paper: Int, grime: Double, grade: FlushGrade, tolerance: Double) -> Double {
        guard paper > 1 else { return 0 }   // one square never blocks anything

        // 2 squares → 0.02, 5 squares → 0.20, before anything else touches it.
        let fromPaper = pow(Double(paper - 1) / 4.0, 1.7) * 0.20
        let fromGrime = 1.0 + grime * 1.4
        let fromPull: Double

        switch grade {
        case .perfect:  fromPull = 0.55     // a proper flush clears a lot
        case .good:     fromPull = 1.0
        case .overheld: fromPull = 1.15
        case .weak:     fromPull = 1.9      // half a flush leaves half of it there
        }

        return min(fromPaper * fromGrime * fromPull / max(tolerance, 0.2), 0.85)
    }

    /// Pumps needed to clear a blockage.
    static let plungesToClear = 5
}
