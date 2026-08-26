import Foundation
import SwiftUI

/// Owns the one thing this app does.
///
/// The visuals are driven entirely by `flushStart` plus `FlushTimeline`, so the
/// engine's only real jobs are starting the noise, keeping the tally, and picking
/// something to say when the water settles.
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

    /// Squares going in on the next flush.
    @Published var paper: Int {
        didSet { defaults.set(paper, forKey: Key.paper) }
    }

    /// True while the bowl is blocked. Nothing flushes until it is cleared.
    @Published private(set) var isClogged = false

    /// Pumps landed on the current blockage.
    @Published private(set) var plunges = 0

    var isClean: Bool { grime <= Upkeep.cleanBelow }

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

    /// Everything earned so far, for the picker.
    var unlockedFixtures: [Fixture] { Fixture.unlocked(at: totalFlushes) }

    private enum Key {
        static let total = "totalFlushes"
        static let golden = "goldenFlushes"
        static let fixture = "equippedFixture"
        static let bestStreak = "bestStreak"
        static let grime = "grime"
        static let paper = "paper"
    }

    private let defaults: UserDefaults
    private var flushTask: Task<Void, Never>?
    private var messageTask: Task<Void, Never>?
    private var celebrationTask: Task<Void, Never>?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let total = defaults.integer(forKey: Key.total)
        totalFlushes = total
        goldenFlushes = defaults.integer(forKey: Key.golden)
        bestStreak = defaults.integer(forKey: Key.bestStreak)
        grime = min(max(defaults.double(forKey: Key.grime), 0), 1)
        paper = defaults.object(forKey: Key.paper) as? Int ?? Upkeep.defaultPaper
        standings = Standings.load(from: defaults)

        // Fall back to the standard toilet if the saved one is unknown, or if the
        // tally was wiped and it is no longer earned. Reads the local rather than
        // the property: `fixture` is not initialised yet.
        let saved = Fixture.with(id: defaults.string(forKey: Key.fixture) ?? Fixture.standard.id)
        fixture = total >= saved.unlockAt ? saved : .standard
    }

    /// Install a fixture. Silently refuses one that has not been earned.
    func equip(_ new: Fixture) {
        guard totalFlushes >= new.unlockAt, new != fixture else { return }
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

        FlushAudio.shared.play(golden: isGolden, voice: fixture.profile)
        Haptics.shared.flush(golden: isGolden)

        flushTask?.cancel()
        // Read the duration before the task: the closure holds self weakly.
        let duration = activeProfile.duration
        flushTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            await self?.settle()
        }
    }

    func resetStats() {
        // A flush settles asynchronously.  Invalidate it before clearing the
        // counters so it cannot write one last flush back after the reset.
        flushTask?.cancel()
        flushTask = nil
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
        standings = Standings()
        Standings.clear(in: defaults)
        setGrime(0)
        paper = Upkeep.defaultPaper
        defaults.set(Upkeep.defaultPaper, forKey: Key.paper)
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

    /// One pump. Five clears it.
    func plunge() {
        guard isClogged else { return }
        plunges += 1
        Haptics.shared.thud()

        guard plunges >= Upkeep.plungesToClear else {
            show(Message(text: "\(Upkeep.plungesToClear - plunges) more", kind: .busy))
            return
        }

        isClogged = false
        plunges = 0
        // Clearing a blockage churns the filth up rather than removing it.
        setGrime(min(grime + 0.08, 1))
        show(Message(text: "Cleared. Try using less next time.", kind: .milestone))
    }

    private func setGrime(_ value: Double) {
        grime = min(max(value, 0), 1)
        defaults.set(grime, forKey: Key.grime)
    }

    // MARK: - Aftermath

    @MainActor
    private func settle() {
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

        standings.record(golden: isGolden, streak: streak)
        standings.save(to: defaults)

        // Every flush leaves a little behind, and paper leaves more.
        setGrime(grime + Upkeep.grimePerFlush * (1 + Double(paper) * 0.25))

        // Then find out whether it went down at all.
        let odds = Upkeep.clogChance(paper: paper,
                                     grime: grime,
                                     grade: grade,
                                     tolerance: fixture.tolerance)
        if Double.random(in: 0..<1) < odds {
            isClogged = true
            plunges = 0
            streak = 0
            Haptics.shared.thud()
            show(Message(text: "Clogged.", kind: .busy))
            return
        }

        // Earning a new toilet outranks anything else the app had to say. The gold
        // still happens on screen, it just does not get the line.
        if let earned = Fixture.all.first(where: { $0.unlockAt > before && $0.unlockAt <= totalFlushes }) {
            show(Message(text: "Unlocked — \(earned.name)", kind: .unlock))
        } else if isGolden {
            show(Message(text: Quips.goldenLine(), kind: .golden))
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
            try? await Task.sleep(for: .seconds(3.4))
            guard !Task.isCancelled else { return }
            await self?.endCelebration()
        }
    }

    @MainActor
    private func endCelebration() {
        withAnimation(.easeInOut(duration: 0.5)) { celebrationStart = nil }
    }

    private func show(_ newMessage: Message) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { message = newMessage }
        messageTask?.cancel()
        messageTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.9))
            guard !Task.isCancelled else { return }
            await self?.dismiss(newMessage.id)
        }
    }

    @MainActor
    private func dismiss(_ id: UUID) {
        guard message?.id == id else { return }
        withAnimation(.easeOut(duration: 0.35)) { message = nil }
    }
}
