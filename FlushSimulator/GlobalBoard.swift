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

    /// Everyone currently waiting on a verdict from GameKit.
    private var waiting: [CheckedContinuation<Void, Never>] = []
    private var isHandlerInstalled = false

    /// How long to wait before admitting Game Center is not going to answer.
    ///
    /// The sign-in sheet can be dismissed in ways that never call back, and a tab
    /// stuck on a spinner forever is worse than one that says it does not know.
    private static let timeout: Duration = .seconds(20)

    /// Has GameKit already told us something we can act on?
    private var hasVerdict: Bool {
        switch state {
        case .signedOut, .failed: return true
        default:                  return false
        }
    }

    // MARK: - Signing in

    /// Asks Game Center who you are, presenting its sign-in sheet if it wants to.
    func authenticate() async {
        guard !isAuthenticated else { return }
        installHandler()

        // GameKit only calls the handler when it has something new to say, so once it
        // has given a verdict, asking again would wait out the timeout for nothing.
        // A later sign-in from Settings calls the handler and corrects this by itself.
        guard !hasVerdict else { return }

        state = .working

        let deadline = Task { [weak self] in
            try? await Task.sleep(for: Self.timeout)
            guard !Task.isCancelled else { return }
            self?.giveUp()
        }
        await withCheckedContinuation { waiting.append($0) }
        deadline.cancel()
    }

    /// GameKit keeps exactly one authenticate handler, and installing a second one
    /// strands whoever was waiting on the first, so it goes in once and everything
    /// that needs a verdict queues up behind it.
    private func installHandler() {
        guard !isHandlerInstalled else { return }
        isHandlerInstalled = true

        GKLocalPlayer.local.authenticateHandler = { viewController, error in
            // GameKit does not promise which thread this arrives on, so hop onto the
            // main actor rather than assuming it.
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let viewController {
                    Self.present(viewController)
                    return                       // the sheet calls back again later
                }
                if let error {
                    self.state = Self.describe(error)
                } else if !GKLocalPlayer.local.isAuthenticated {
                    self.state = .signedOut
                }
                self.wakeWaiters()
            }
        }
    }

    private func giveUp() {
        if case .working = state { state = .failed("Game Center didn't answer.") }
        wakeWaiters()
    }

    private func wakeWaiters() {
        let waiters = waiting
        waiting = []
        waiters.forEach { $0.resume() }
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
            state = Self.describe(error)
        }
    }

    /// An unconfigured leaderboard and a network failure look similar from here, so
    /// go by what GameKit actually said rather than assuming the usual case. The one
    /// unambiguous signal for "not configured" is a board that simply is not there,
    /// which `refresh` reads off an empty result rather than off a thrown error.
    private static func describe(_ error: Error) -> State {
        let failure = error as NSError
        guard failure.domain == GKErrorDomain,
              let code = GKError.Code(rawValue: failure.code)
        else { return .failed(error.localizedDescription) }

        switch code {
        case .notAuthenticated, .invalidCredentials, .notAuthorized, .userDenied, .cancelled:
            return .signedOut
        case .gameUnrecognized, .notSupported, .apiNotAvailable:
            return .notConfigured
        default:
            return .failed(error.localizedDescription)
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

    /// The leaderboard is itself a sheet, so the root view controller is already
    /// presenting by the time Game Center asks for its own. Presenting on a
    /// controller that is already presenting is refused outright and the sign-in
    /// sheet never appears, so walk to whatever is actually on top.
    private static func present(_ viewController: UIViewController) {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        guard let root = scene?.keyWindow?.rootViewController else { return }

        var top = root
        while let next = top.presentedViewController, !next.isBeingDismissed { top = next }
        guard top.presentedViewController == nil else { return }

        top.present(viewController, animated: true)
    }
}
