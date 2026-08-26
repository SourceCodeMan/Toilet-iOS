import Foundation

/// Wholly unearned titles, handed out for pushing a lever.
struct Rank: Equatable {
    let threshold: Int
    let title: String
    let symbol: String

    static let all: [Rank] = [
        Rank(threshold: 0,    title: "Bathroom Rookie",          symbol: "figure.walk"),
        Rank(threshold: 1,    title: "Handle Enthusiast",        symbol: "hand.point.up.left.fill"),
        Rank(threshold: 5,    title: "Certified Flusher",        symbol: "checkmark.seal.fill"),
        Rank(threshold: 15,   title: "Porcelain Apprentice",     symbol: "drop.fill"),
        Rank(threshold: 40,   title: "Chain Puller, 1st Class",  symbol: "link"),
        Rank(threshold: 80,   title: "Master of Ceremonies",     symbol: "sparkles"),
        Rank(threshold: 150,  title: "Duke of the Water Closet", symbol: "shield.lefthalf.filled"),
        Rank(threshold: 300,  title: "Sultan of Swirl",          symbol: "tornado"),
        Rank(threshold: 600,  title: "Grand Poobah of Plumbing", symbol: "wrench.and.screwdriver.fill"),
        Rank(threshold: 1000, title: "Their Royal Flushness",    symbol: "crown.fill")
    ]

    static func current(for flushes: Int) -> Rank {
        all.last { flushes >= $0.threshold } ?? all[0]
    }

    static func next(after flushes: Int) -> Rank? {
        all.first { flushes < $0.threshold }
    }

    /// Progress from the current rank to the next one, 0...1.
    static func progress(for flushes: Int) -> Double {
        let now = current(for: flushes)
        guard let next = next(after: flushes) else { return 1 }
        let span = Double(next.threshold - now.threshold)
        guard span > 0 else { return 1 }
        return min(max(Double(flushes - now.threshold) / span, 0), 1)
    }
}
