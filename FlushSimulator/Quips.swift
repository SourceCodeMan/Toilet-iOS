import Foundation

/// The things the app says to you after you have flushed a toilet on your phone.
enum Quips {

    private static let afterFlush = [
        "Whoosh. Textbook.",
        "Gone. Reduced to atoms.",
        "Somewhere, a plumber nodded.",
        "Judges: 10, 10, 9.5.",
        "That one had real range.",
        "The porcelain remembers.",
        "Water bill: +$0.004",
        "Certified fresh.",
        "Nothing but net.",
        "Balance has been restored to the bowl.",
        "Smooth. Professional. Devastating.",
        "The tank respects you now.",
        "A masterclass in handle work.",
        "Local plumbing: shaken.",
        "10/10, would flush again.",
        "That's going in the highlight reel.",
        "Physics: satisfied.",
        "No notes.",
        "Somewhere, a duck applauded.",
        "The swirl was, frankly, art.",
        "Clean exit. No witnesses.",
        "You've still got it."
    ]

    private static let whileBusy = [
        "Let it finish, champ.",
        "Patience. The tank is refilling.",
        "One at a time. House rules.",
        "It's still going. Look at it go.",
        "Easy, tiger.",
        "You cannot rush a classic."
    ]

    private static let golden = [
        "A GOLDEN FLUSH. Tell someone.",
        "GOLDEN FLUSH. The rarest swirl.",
        "GOLDEN FLUSH. You lucky thing."
    ]

    /// Pinned to the main actor rather than left a free-floating mutable global,
    /// which is an error under Swift 6. Everything that asks for a line is already
    /// on the main actor anyway.
    @MainActor private static var lastLine: String?

    @MainActor static func afterFlushLine() -> String { pick(from: afterFlush) }
    @MainActor static func busyLine() -> String { pick(from: whileBusy) }
    @MainActor static func goldenLine() -> String { pick(from: golden) }

    /// A line for round numbers, because round numbers deserve acknowledgement.
    static func milestone(for count: Int) -> String? {
        switch count {
        case 1:    return "Your first flush. They grow up so fast."
        case 10:   return "Ten flushes. A hobby is forming."
        case 25:   return "25 flushes. This is a lifestyle now."
        case 50:   return "50 flushes. Someone should check on you."
        case 100:  return "100 flushes. Impressive. Slightly worrying."
        case 250:  return "250 flushes. You ARE the plumbing."
        case 500:  return "500 flushes. Historians will study this."
        case 1000: return "1,000 flushes. There is nothing left to teach you."
        default:   return nil
        }
    }

    /// Never the same line twice in a row, which is most of what makes it feel written.
    @MainActor private static func pick(from lines: [String]) -> String {
        let choices = lines.count > 1 ? lines.filter { $0 != lastLine } : lines
        let line = choices.randomElement() ?? lines[0]
        lastLine = line
        return line
    }
}
