import Foundation

/// One puzzle a day, the same for everybody, one attempt.
///
/// Endless play has no reason to bring you back tomorrow — the tally only ever goes
/// up. A daily is the cheapest fix for that: a fixed set of conditions derived from
/// the date itself, so nothing has to be fetched or agreed on, and a score you can
/// compare because everyone got the same bowl.
struct DailyChallenge: Equatable {

    /// Days since the reference date, the same stamp `Standings` keeps.
    let stamp: Int
    let fixtureID: String
    /// How dirty it starts. Neglect you inherit rather than caused.
    let startingGrime: Double
    /// Squares the day asks for. Hitting it exactly pays a bonus.
    let paperTarget: Int

    /// Flushes in a run. Short on purpose: a daily should be one sitting.
    static let flushCount = 5

    /// What hitting the paper target is worth.
    static let targetBonus = 1.5

    var fixture: Fixture { Fixture.with(id: fixtureID) }

    /// Which day this is, counting from the first one.
    var number: Int { stamp - 9_300 }

    static func today(_ date: Date = Date()) -> DailyChallenge {
        forStamp(Standings.stamp(for: date))
    }

    /// Derived from the date and nothing else, so two phones agree without talking.
    static func forStamp(_ stamp: Int) -> DailyChallenge {
        var rng = SplitMix(seed: UInt64(bitPattern: Int64(stamp)))
        let pick = Fixture.all[Int(rng.next(below: UInt64(Fixture.all.count)))]
        return DailyChallenge(
            stamp: stamp,
            fixtureID: pick.id,
            startingGrime: Double(rng.next(below: 50)) / 100,          // 0 ... 0.49
            paperTarget: 1 + Int(rng.next(below: 5))                   // 1 ... 5
        )
    }
}

/// How one flush of a daily went.
enum DailyMark: String, Codable {
    case golden, perfect, good, poor, clogged

    /// The share grid. Deliberately the same shapes everyone already reads.
    var emoji: String {
        switch self {
        case .golden:  return "🟨"
        case .perfect: return "🟩"
        case .good:    return "🟦"
        case .poor:    return "⬜"
        case .clogged: return "🟥"
        }
    }
}

/// Your attempt at a given day.
struct DailyResult: Codable, Equatable {
    var stamp: Int
    var marks: [DailyMark] = []
    var score: Int = 0

    var isComplete: Bool { marks.count >= DailyChallenge.flushCount }

    private static let key = "dailyResult"

    static func load(from defaults: UserDefaults) -> DailyResult? {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(DailyResult.self, from: data)
        else { return nil }
        // Yesterday's attempt is not today's.
        return decoded.stamp == Standings.stamp(for: Date()) ? decoded : nil
    }

    func save(to defaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.key)
    }

    static func clear(in defaults: UserDefaults) { defaults.removeObject(forKey: key) }

    /// What gets copied out. No link, no tracking, just the grid.
    func shareText(for challenge: DailyChallenge) -> String {
        """
        Flush Simulator — Daily #\(challenge.number)
        \(marks.map(\.emoji).joined())
        \(score.formatted()) points · \(challenge.fixture.name)
        """
    }
}

/// A small deterministic generator, so a given day is the same day everywhere.
///
/// `Double.random` would do the opposite of what a daily needs.
struct SplitMix {
    private var state: UInt64

    init(seed: UInt64) { state = seed &* 0x9E37_79B9_7F4A_7C15 &+ 0x1234_5678_9ABC_DEF1 }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    mutating func next(below bound: UInt64) -> UInt64 { bound == 0 ? 0 : next() % bound }
}
