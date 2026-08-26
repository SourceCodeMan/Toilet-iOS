import GameKit
import SwiftUI

/// The global leaderboard, via Game Center.
///
/// Game Center itself is free, but the leaderboards live in App Store Connect, which
/// needs a paid membership to configure. Until that exists this will authenticate and
/// then fail to find the board — so every failure here is reported plainly rather than
/// swallowed, and nothing else in the app depends on it working.
///
/// Nothing happens until someone asks for it. Authenticating on launch would throw a
/// Game Center sign-in sheet at people who only wanted to flush a toilet.
@MainActor
final class GlobalBoard: ObservableObject {

    /// Create these in App Store Connect once the membership is live. The IDs are the
    /// contract between this file and that config; they are not discoverable.
    enum ID {
        static let lifetime = "com.tomchapman.flushsimulator.lifetime"
        static let bestDay = "com.tomchapman.flushsimulator.bestday"
    }

    struct Entry: Identifiable {
        let id: String
        let rank: Int
        let name: String
        let score: Int
        let isYou: Bool
    }

    enum State: Equatable {
        case idle
        case working
        case signedOut
        /// Authenticated, but the board is not configured on Apple's side yet.
        case notConfigured
        case failed(String)
        case ready([Entry])

        static func == (a: State, b: State) -> Bool {
            switch (a, b) {
            case (.idle, .idle), (.working, .working), (.signedOut, .signedOut),
                 (.notConfigured, .notConfigured):                       return true
            case let (.failed(x), .failed(y)):                           return x == y
            case let (.ready(x), .ready(y)):                             return x.count == y.count
            default:                                                     return false
            }
        }
    }

    @Published private(set) var state: State = .idle

    private var isAuthenticated: Bool { GKLocalPlayer.local.isAuthenticated }

    // MARK: - Signing in

    /// Asks Game Center who you are, presenting its sign-in sheet if it wants to.
    func authenticate() async {
        guard !isAuthenticated else { return }
        state = .working

        await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
            var resumed = false
            GKLocalPlayer.local.authenticateHandler = { viewController, error in
                if let viewController {
                    Self.present(viewController)
                    return                       // the sheet calls back again later
                }
                guard !resumed else { return }
                resumed = true

                if let error {
                    self.state = .failed(error.localizedDescription)
                } else if !GKLocalPlayer.local.isAuthenticated {
                    self.state = .signedOut
                }
                done.resume()
            }
        }
    }

    // MARK: - Reading and writing

    /// Sign in if needed, then load the standings around you.
    func refresh() async {
        await authenticate()
        guard isAuthenticated else {
            if state == .working { state = .signedOut }
            return
        }
        state = .working

        do {
            let boards = try await GKLeaderboard.loadLeaderboards(IDs: [ID.lifetime])
            guard let board = boards.first else {
                state = .notConfigured
                return
            }

            let (mine, top, _) = try await board.loadEntries(for: .global,
                                                             timeScope: .allTime,
                                                             range: NSRange(location: 1, length: 20))
            let me = GKLocalPlayer.local.gamePlayerID
            state = .ready(top.map {
                Entry(id: $0.player.gamePlayerID + "#\($0.rank)",
                      rank: $0.rank,
                      name: $0.player.displayName,
                      score: $0.score,
                      isYou: $0.player.gamePlayerID == me || $0.rank == mine?.rank)
            })
        } catch {
            // An unconfigured leaderboard and a network failure look similar from
            // here, so say which one we believe it is rather than guessing wrongly.
            state = .notConfigured
        }
    }

    /// Push the current totals up. Silently does nothing if Game Center is not ready,
    /// which is the correct behaviour for something the player did not ask for.
    func submit(lifetime: Int, bestDay: Int) async {
        guard isAuthenticated else { return }
        try? await GKLeaderboard.submitScore(lifetime, context: 0,
                                             player: GKLocalPlayer.local,
                                             leaderboardIDs: [ID.lifetime])
        try? await GKLeaderboard.submitScore(bestDay, context: 0,
                                             player: GKLocalPlayer.local,
                                             leaderboardIDs: [ID.bestDay])
    }

    // MARK: - Plumbing

    private static func present(_ viewController: UIViewController) {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        scene?.keyWindow?.rootViewController?.present(viewController, animated: true)
    }
}
