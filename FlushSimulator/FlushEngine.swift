import Foundation
import SwiftUI

/// Owns the one thing this app does.
///
/// The visuals are driven entirely by `flushStart` plus `FlushTimeline`, so the
/// engine's only real jobs are starting the noise, keeping the tally, and picking
/// something to say when the water settles.
final class FlushEngine: ObservableObject {

    struct Message: Equatable, Identifiable {
        enum Kind { case quip, milestone, golden, busy }
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

    /// One flush in this many is golden.
    private static let goldenOdds = 20

    private enum Key {
        static let total = "totalFlushes"
        static let golden = "goldenFlushes"
    }

    private let defaults: UserDefaults
    private var flushTask: Task<Void, Never>?
    private var messageTask: Task<Void, Never>?
    private var celebrationTask: Task<Void, Never>?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        totalFlushes = defaults.integer(forKey: Key.total)
        goldenFlushes = defaults.integer(forKey: Key.golden)
    }

    var isFlushing: Bool { flushStart != nil }

    /// True while the whole app should go gold.
    var showsGold: Bool { isGolden && (isFlushing || celebrationStart != nil) }

    // MARK: - The button

    func pullHandle() {
        guard !isFlushing else {
            Haptics.shared.thud()
            show(Message(text: Quips.busyLine(), kind: .busy))
            return
        }

        isGolden = Int.random(in: 0..<Self.goldenOdds) == 0
        flushStart = Date()
        withAnimation(.easeOut(duration: 0.25)) { message = nil }

        FlushAudio.shared.play(golden: isGolden)
        Haptics.shared.flush(golden: isGolden)

        flushTask?.cancel()
        flushTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(FlushTimeline.duration))
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
        defaults.set(0, forKey: Key.total)
        defaults.set(0, forKey: Key.golden)
        show(Message(text: "A clean slate. Literally.", kind: .quip))
    }

    // MARK: - Aftermath

    @MainActor
    private func settle() {
        flushStart = nil
        // Animated so the counter rolls over rather than snapping.
        withAnimation(.snappy) { totalFlushes += 1 }
        defaults.set(totalFlushes, forKey: Key.total)

        if isGolden {
            withAnimation(.snappy) { goldenFlushes += 1 }
            defaults.set(goldenFlushes, forKey: Key.golden)
            show(Message(text: Quips.goldenLine(), kind: .golden))
            celebrate()
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
