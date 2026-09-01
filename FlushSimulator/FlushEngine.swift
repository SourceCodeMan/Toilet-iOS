import Foundation
import SwiftUI

/// Owns the one thing this app does.
///
/// The visuals are driven entirely by `flushStart` plus `FlushTimeline`, so the
/// engine's only real jobs are starting the noise, keeping the tally, and picking
/// something to say when the water settles.
@MainActor
final class FlushEngine: ObservableObject {

    struct Message: Equatable, Identifiable {
        enum Kind { case quip, milestone, golden, busy, unlock }
        let id = UUID()
        let text: String
        let kind: Kind
    }

    /// When the current flush began, or nil if the bowl is at rest.
    @Published private(set) var flushStart: Date?
    @Published private(set) var isGolden = false
    @Published private(set) var totalFlushes: Int
    @Published private(set) var goldenFlushes: Int
    @Published private(set) var message: Message?
    @Published private(set) var celebrationStart: Date?

    /// Consecutive perfect pulls. Resets on a weak or overheld one.
    @Published private(set) var streak = 0

    /// The best run of perfect pulls so far.
    @Published private(set) var bestStreak: Int

    /// How the flush currently running was pulled.
    @Published private(set) var grade: FlushGrade = .good

    /// How filthy the bowl is, 0...1.
    @Published private(set) var grime: Double

    // MARK: - The roll on the wall

    /// Squares hanging off the roll, pulled but not yet torn.
    @Published private(set) var paperPulled = 0

    /// True once the sheet has been torn off and is sitting ready.
    @Published private(set) var isPaperCut = false

    /// The sheet was never torn, so the flush dragged the roll in with it. Nothing
    /// clears until it is cut free.
    @Published private(set) var isPaperTrailing = false

    /// What actually goes down on this flush.
    ///
    /// An uncut sheet does not go down as a tidy stack: the bowl keeps pulling for
    /// the whole flush, so it counts as far more than was ever hanging there. Pulling
    /// nothing at all is not the same thing as leaving it attached, though — an empty
    /// roll is uncut by definition, and that must not read as a runaway.
    var loadedPaper: Int {
        guard paperPulled > 0 else { return 0 }
        return isPaperCut ? paperPulled : Upkeep.runawayPaper
    }

    /// True while the bowl is blocked. Nothing flushes until it is cleared.
    @Published private(set) var isClogged = false

    /// Whether the blockage was a whole roll rather than an ordinary overload.
    private var wasRunaway = false

    /// Pumps landed on the current blockage.
    @Published private(set) var plunges = 0

    /// Day-by-day record, for the leaderboard.
    @Published private(set) var standings: Standings

    /// The profile actually driving the flush on screen: the fixture's, scaled by
    /// how well the handle was pulled.
    var activeProfile: FlushProfile { grade.apply(to: fixture.profile) }

    /// Everything that decides how often gold turns up lives in `Upkeep`.
    private var goldenChance: Double {
        Upkeep.goldenChance(streak: streak, grime: grime)
    }

    /// The bowl is bad enough that flushing it costs you the run.
    var isFilthy: Bool { grime >= Upkeep.filthyAbove }

    /// The fixture currently installed. Its profile drives the flush and its
    /// palette dresses the app.
    @Published private(set) var fixture: Fixture

    /// How this fixture flushes and sounds.
    var profile: FlushProfile { fixture.profile }

    private enum Key {
        static let total = "totalFlushes"
        static let golden = "goldenFlushes"
        static let fixture = "equippedFixture"
        static let bestStreak = "bestStreak"
        static let grime = "grime"
    }

    private let defaults: UserDefaults
    private var flushTask: Task<Void, Never>?

    /// Bumped whenever a flush is started or thrown away. A settle that belongs to
    /// an older generation has been overtaken and must not write anything back.
    private var generation = 0
    private var messageTask: Task<Void, Never>?
    private var celebrationTask: Task<Void, Never>?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let total = defaults.integer(forKey: Key.total)
        totalFlushes = total
        goldenFlushes = defaults.integer(forKey: Key.golden)
        bestStreak = defaults.integer(forKey: Key.bestStreak)
        grime = min(max(defaults.double(forKey: Key.grime), 0), 1)
        standings = Standings.load(from: defaults)

        // Fall back to the standard toilet if the saved one is unknown, or if the
        // tally was wiped and it is no longer earned. Reads the local rather than
        // the property: `fixture` is not initialised yet.
        let saved = Fixture.with(id: defaults.string(forKey: Key.fixture) ?? Fixture.standard.id)
        fixture = total >= saved.unlockAt ? saved : .standard
    }

    /// Install a fixture. Silently refuses one that has not been earned, and says so
    /// about one asked for mid-flush.
    func equip(_ new: Fixture) {
        guard totalFlushes >= new.unlockAt, new != fixture else { return }

        // Swapping mid-flush would pull the profile out from under the running
        // animation while the flush still ends on the old fixture's duration.
        guard !isFlushing else {
            Haptics.shared.thud()
            show(Message(text: "Not mid-flush.", kind: .busy))
            return
        }

        withAnimation(.snappy) { fixture = new }
        defaults.set(new.id, forKey: Key.fixture)
        FlushAudio.shared.prepare(new.profile)
        Haptics.shared.thud()
        show(Message(text: new.blurb, kind: .unlock))
    }

    var isFlushing: Bool { flushStart != nil }

    /// True while the whole app should go gold.
    var showsGold: Bool { isGolden && (isFlushing || celebrationStart != nil) }

    // MARK: - The button

    func pullHandle(_ pulled: FlushGrade = .good) {
        guard !isClogged else {
            Haptics.shared.thud()
            show(Message(text: "Blocked. Plunge it.", kind: .busy))
            return
        }
        guard !isFlushing else {
            Haptics.shared.thud()
            show(Message(text: Quips.busyLine(), kind: .busy))
            return
        }

        // Settle the streak before the odds are rolled, so a perfect pull pays out
        // on the flush that earned it rather than the next one.
        if isFilthy {
            // Nothing you do at the handle survives a bowl in this state.
            streak = 0
        } else if pulled.keepsStreak {
            streak += 1
            if streak > bestStreak {
                bestStreak = streak
                defaults.set(bestStreak, forKey: Key.bestStreak)
            }
        } else if pulled.breaksStreak {
            streak = 0
        }

        grade = pulled
        isGolden = Double.random(in: 0..<1) < goldenChance
        flushStart = Date()
        withAnimation(.easeOut(duration: 0.25)) { message = nil }

        // The picture is graded, the noise and the buzz are not: both are cached per
        // fixture, and a cistern refills in its own time however you pulled the lever.
        FlushAudio.shared.play(golden: isGolden, voice: fixture.profile)
        Haptics.shared.flush(golden: isGolden, scale: fixture.profile.timeScale)

        flushTask?.cancel()
        generation += 1
        // Read these before the task: the closure holds self weakly.
        let duration = activeProfile.duration
        let mine = generation
        flushTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            self?.settle(mine)
        }
    }

    func resetStats() {
        // A flush settles asynchronously. Cancelling is not enough on its own: the
        // task checks for cancellation before hopping back here, so a reset landing
        // in that window would still get one last flush written back. Moving the
        // generation on is what actually invalidates it.
        flushTask?.cancel()
        flushTask = nil
        generation += 1
        flushStart = nil
        isGolden = false

        celebrationTask?.cancel()
        celebrationTask = nil
        celebrationStart = nil
        FlushAudio.shared.stop()

        totalFlushes = 0
        goldenFlushes = 0
        streak = 0
        bestStreak = 0
        defaults.set(0, forKey: Key.bestStreak)
        isClogged = false
        plunges = 0
        paperPulled = 0
        isPaperCut = false
        isPaperTrailing = false
        wasRunaway = false
        standings = Standings()
        Standings.clear(in: defaults)
        setGrime(0)
        // The standard toilet is the only one left standing after a wipe.
        fixture = .standard
        defaults.set(Fixture.standard.id, forKey: Key.fixture)
        defaults.set(0, forKey: Key.total)
        defaults.set(0, forKey: Key.golden)
        show(Message(text: "A clean slate. Literally.", kind: .quip))
    }

    // MARK: - Upkeep

    /// Scrub it. Costs you nothing but the time, and a clean bowl flushes gold
    /// more often.
    func useWand() {
        guard !isFlushing, grime > 0 else { return }
        let wasFilthy = grime >= Upkeep.grimyAbove
        withAnimation(.easeInOut(duration: 0.5)) { grime = 0 }
        defaults.set(0.0, forKey: Key.grime)
        Haptics.shared.tick()
        show(Message(text: wasFilthy ? "Spotless. That was overdue." : "Spotless.",
                     kind: .unlock))
    }

    // MARK: - The roll

    /// Draw the sheet down. Called continuously while a finger drags it.
    func pullPaper(to squares: Int) {
        guard !isFlushing, !isClogged, !isPaperCut else { return }
        let wanted = min(max(squares, 0), Upkeep.paperRange.upperBound)
        guard wanted != paperPulled else { return }
        paperPulled = wanted
        Haptics.shared.tick()
    }

    /// Tear it off. Until this happens the sheet is still attached to the roll.
    func cutPaper() {
        guard paperPulled > 0 else { return }

        // Cutting a sheet that a flush already dragged in is the first step out of
        // the blockage, not a normal tear.
        if isPaperTrailing {
            isPaperTrailing = false
            paperPulled = 0
            isPaperCut = false
            Haptics.shared.thud()
            show(Message(text: "Cut free. Now plunge it.", kind: .busy))
            return
        }

        guard !isPaperCut else { return }
        isPaperCut = true
        Haptics.shared.tick()
    }

    /// One pump. Five clears it.
    func plunge() {
        guard isClogged else { return }
        guard !isPaperTrailing else {
            Haptics.shared.thud()
            show(Message(text: "It's still attached. Cut it.", kind: .busy))
            return
        }
        plunges += 1
        Haptics.shared.thud()

        guard plunges >= Upkeep.plungesToClear else {
            show(Message(text: "\(Upkeep.plungesToClear - plunges) more", kind: .busy))
            return
        }

        isClogged = false
        plunges = 0
        // Clearing a blockage churns the filth up rather than removing it. A whole
        // roll going down leaves the bowl in a state the wand is the only answer to.
        setGrime(wasRunaway ? max(grime, Upkeep.filthyAbove + 0.02) : min(grime + 0.08, 1))
        wasRunaway = false
        show(Message(text: "Cleared. Try using less next time.", kind: .milestone))
    }

    private func setGrime(_ value: Double) {
        grime = min(max(value, 0), 1)
        defaults.set(grime, forKey: Key.grime)
    }

    // MARK: - Aftermath

    private func settle(_ mine: Int) {
        // Overtaken by a reset, or by a flush that started after this one.
        guard mine == generation else { return }

        flushStart = nil
        let before = totalFlushes
        // Animated so the counter rolls over rather than snapping.
        withAnimation(.snappy) { totalFlushes += 1 }
        defaults.set(totalFlushes, forKey: Key.total)

        if isGolden {
            withAnimation(.snappy) { goldenFlushes += 1 }
            defaults.set(goldenFlushes, forKey: Key.golden)
            celebrate()
        }

        // A sheet still attached to the roll is not a quantity, it is an accident.
        let runaway = paperPulled > 0 && !isPaperCut
        let load = loadedPaper

        standings.record(golden: isGolden,
                         streak: streak,
                         points: runaway ? 0 : Upkeep.points(paper: load, golden: isGolden))
        standings.save(to: defaults)

        // Every flush leaves a little behind, and paper leaves more.
        setGrime(grime + Upkeep.grimePerFlush * (1 + Double(load) * 0.25))

        // Then find out whether it went down at all. A runaway roll is not a roll of
        // the dice — it blocks, every time.
        let odds = Upkeep.clogChance(paper: load,
                                     grime: grime,
                                     grade: grade,
                                     tolerance: fixture.tolerance)
        if runaway || Double.random(in: 0..<1) < odds {
            isClogged = true
            wasRunaway = runaway
            isPaperTrailing = runaway
            plunges = 0
            streak = 0
            Haptics.shared.thud()
            show(Message(text: runaway ? "The whole roll went in." : "Clogged.", kind: .busy))
            return
        }

        // A tidy flush takes the sheet with it and leaves the roll ready again.
        paperPulled = 0
        isPaperCut = false

        // Earning a new toilet outranks anything else the app had to say. The gold
        // still happens on screen, it just does not get the line.
        if let earned = Fixture.all.first(where: { $0.unlockAt > before && $0.unlockAt <= totalFlushes }) {
            show(Message(text: "Unlocked — \(earned.name)", kind: .unlock))
        } else if isGolden {
            show(Message(text: Quips.goldenLine(), kind: .golden))
        } else if load == 0 {
            // Flushing nothing but water is its own kind of achievement.
            show(Message(text: Quips.unwipedLine(), kind: .busy))
        } else if grade == .perfect, streak >= 2 {
            show(Message(text: "Perfect ×\(streak)", kind: .milestone))
        } else if grade == .weak || grade == .overheld {
            show(Message(text: grade.label, kind: .busy))
        } else if isFilthy {
            show(Message(text: "Too filthy. No streak, no gold.", kind: .busy))
        } else if grime >= Upkeep.grimyAbove {
            show(Message(text: "That bowl needs a wand.", kind: .busy))
        } else if let milestone = Quips.milestone(for: totalFlushes) {
            show(Message(text: milestone, kind: .milestone))
        } else {
            show(Message(text: Quips.afterFlushLine(), kind: .quip))
        }
    }

    private func celebrate() {
        celebrationStart = Date()
        celebrationTask?.cancel()
        celebrationTask = Task { [weak self] in
            // Longer than the slowest flake takes to fall (3.75s), so the gold
            // lands rather than blinking out mid-air.
            try? await Task.sleep(for: .seconds(3.8))
            guard !Task.isCancelled else { return }
            self?.endCelebration()
        }
    }

    private func endCelebration() {
        withAnimation(.easeInOut(duration: 0.5)) { celebrationStart = nil }
    }

    private func show(_ newMessage: Message) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { message = newMessage }
        messageTask?.cancel()
        messageTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.9))
            guard !Task.isCancelled else { return }
            self?.dismiss(newMessage.id)
        }
    }

    private func dismiss(_ id: UUID) {
        guard message?.id == id else { return }
        withAnimation(.easeOut(duration: 0.35)) { message = nil }
    }
}
