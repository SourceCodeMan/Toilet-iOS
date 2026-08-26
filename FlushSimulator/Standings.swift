import Foundation

/// What you have flushed, and when.
///
/// A leaderboard in a one-player app has to rank you against something, so it ranks
/// you against your own days. Each day gets a tally; the board is your best days,
/// with today marked so you can see what you have to beat.
///
/// Kept as a small rolling history rather than every day forever — the board only
/// ever shows a handful, and nobody needs a diary of this.
struct Standings: Codable, Equatable {

    struct Day: Codable, Equatable, Identifiable {
        /// Days since the reference date. Cheap to compare, cheap to store, and it
        /// does not drift the way a formatted date string would.
        let stamp: Int
        var flushes: Int
        var golden: Int
        var bestStreak: Int

        var id: Int { stamp }
    }

    /// Newest first.
    private(set) var days: [Day] = []

    /// How many days of history to keep.
    static let historyLimit = 60

    /// How many rows the board shows.
    static let boardLength = 10

    // MARK: - Recording

    static func stamp(for date: Date, calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: date)
        return Int(start.timeIntervalSinceReferenceDate / 86_400)
    }

    /// Add one flush to today's tally.
    mutating func record(golden: Bool, streak: Int, on date: Date = Date()) {
        let today = Self.stamp(for: date)

        if let i = days.firstIndex(where: { $0.stamp == today }) {
            days[i].flushes += 1
            if golden { days[i].golden += 1 }
            days[i].bestStreak = max(days[i].bestStreak, streak)
        } else {
            days.insert(Day(stamp: today,
                            flushes: 1,
                            golden: golden ? 1 : 0,
                            bestStreak: streak),
                        at: 0)
            days.sort { $0.stamp > $1.stamp }
            if days.count > Self.historyLimit {
                days.removeLast(days.count - Self.historyLimit)
            }
        }
    }

    // MARK: - Reading

    var today: Day? {
        let stamp = Self.stamp(for: Date())
        return days.first { $0.stamp == stamp }
    }

    /// Best days first, ties broken by the more recent day.
    var board: [Day] {
        days.sorted {
            $0.flushes == $1.flushes ? $0.stamp > $1.stamp : $0.flushes > $1.flushes
        }
        .prefix(Self.boardLength)
        .map { $0 }
    }

    /// Where today sits on that board, 1-based, or nil if it has not made it.
    var todaysRank: Int? {
        guard let today else { return nil }
        return board.firstIndex(where: { $0.stamp == today.stamp }).map { $0 + 1 }
    }

    var bestDay: Day? { board.first }

    // MARK: - Storage

    private static let key = "standings"

    static func load(from defaults: UserDefaults = .standard) -> Standings {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(Standings.self, from: data)
        else { return Standings() }
        return decoded
    }

    func save(to defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.key)
    }

    static func clear(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }

    /// A short label for a row: "Today", "Yesterday", or a date.
    static func label(for stamp: Int, calendar: Calendar = .current) -> String {
        let now = Self.stamp(for: Date(), calendar: calendar)
        switch now - stamp {
        case 0:  return "Today"
        case 1:  return "Yesterday"
        default:
            let date = Date(timeIntervalSinceReferenceDate: Double(stamp) * 86_400)
            let f = DateFormatter()
            f.dateFormat = "d MMM"
            return f.string(from: date)
        }
    }
}
