import SwiftUI

/// A toilet you can own.
///
/// A fixture is only ever a palette and a set of numbers — no new geometry, no new
/// layout. The porcelain is drawn from `Palette`, and the flush is driven by
/// `FlushProfile`, so a new toilet costs about thirty lines and no new drawing code.
/// What the room around a fixture is made of.
enum RoomSurface {
    case tile       // ordinary bathroom
    case planks     // weathered boards
    case ornate     // panelling and gilt
    case panels     // brushed steel seams
    case bulkhead   // an instrument-lit hull
}

struct Fixture: Identifiable, Equatable, Sendable {

    let id: String
    let name: String

    /// The line shown when it unlocks, and in the picker underneath the name.
    let blurb: String

    /// Lifetime flushes needed. The first one is free.
    let unlockAt: Int

    /// How much abuse the drain takes before it blocks. 1.0 is ordinary domestic
    /// plumbing; below that blocks easily, above that swallows nearly anything.
    let tolerance: Double

    /// What a flush here is worth, as a multiplier.
    ///
    /// Deliberately the inverse of `tolerance`: the drain that swallows anything
    /// pays the least, and the one that blocks if you look at it pays the most. That
    /// is what turns the collection from a set of skins into a choice — without it
    /// there is never a reason not to equip the most forgiving toilet you own.
    let payout: Double

    /// SF Symbol for the picker chip.
    let symbol: String

    /// What the walls and floor are made of.
    let surface: RoomSurface

    /// How this one flushes and how it sounds.
    let profile: FlushProfile

    /// Built per colour scheme, the same way `Palette.standard` always was.
    let palette: @Sendable (ColorScheme) -> Palette

    static func == (a: Fixture, b: Fixture) -> Bool { a.id == b.id }

    // MARK: - The catalogue

    static let all: [Fixture] = [standard, outhouse, victorian, chrome, orbital]

    static func with(id: String) -> Fixture {
        all.first { $0.id == id } ?? standard
    }

    // MARK: - Fixtures

    static let standard = Fixture(
        id: "standard",
        name: "Standard Issue",
        blurb: "The one you already have.",
        unlockAt: 0,
        tolerance: 1.0,
        payout: 1.00,        // The bar everything else is measured against.
        symbol: "house.fill",
        surface: .tile,
        profile: .standard,
        palette: Palette.standard
    )

    /// Slow, hollow, and wooden. Barely any tank to speak of.
    static let outhouse = Fixture(
        id: "outhouse",
        name: "The Outhouse",
        blurb: "No plumbing. Just gravity and hope.",
        unlockAt: 25,
        tolerance: 0.55,
        payout: 1.60,        // Blocks constantly, so it has to pay for the trouble.
        symbol: "tree.fill",
        surface: .planks,
        profile: FlushProfile(
            duration: 4.2,
            restingLevel: 0.38,
            surgePeak: 0.72,
            spinPeak: 700,
            rumbleScale: 2.6,
            chop: 0.020,
            clunkFrequency: 62,
            roarFrom: 640,
            roarTo: 180,
            bodyFrequency: 96,
            gurgleCentre: 380,
            gurgleSwing: 190,
            hissFrom: 900,
            hissTo: 1_250,
            valveFrequency: 74
        ),
        palette: Palette.outhouse
    )

    /// A high cistern and a long chain. Takes its time, and is smug about it.
    static let victorian = Fixture(
        id: "victorian",
        name: "Victorian Throne",
        blurb: "A high cistern, and no hurry whatsoever.",
        unlockAt: 100,
        tolerance: 0.8,
        payout: 1.25,        // Fussy enough to be worth something.
        symbol: "crown.fill",
        surface: .ornate,
        profile: FlushProfile(
            duration: 4.6,
            restingLevel: 0.55,
            surgePeak: 0.99,
            spinPeak: 1_050,
            rumbleScale: 1.2,
            chop: 0.010,
            clunkFrequency: 128,
            roarFrom: 1_020,
            roarTo: 300,
            bodyFrequency: 140,
            gurgleCentre: 520,
            gurgleSwing: 300,
            hissFrom: 1_700,
            hissTo: 2_600,
            valveFrequency: 96
        ),
        palette: Palette.victorian
    )

    /// Airport-grade. Violent, brief, and far too loud.
    static let chrome = Fixture(
        id: "chrome",
        name: "Chrome Pressure",
        blurb: "Commercial grade. Startles everyone.",
        unlockAt: 400,
        tolerance: 1.9,
        payout: 0.70,        // Swallows nearly anything, so it pays the least.
        symbol: "bolt.fill",
        surface: .panels,
        profile: FlushProfile(
            duration: 2.6,
            restingLevel: 0.48,
            surgePeak: 0.88,
            spinPeak: 2_300,
            rumbleScale: 3.1,
            chop: 0.022,
            clunkFrequency: 150,
            roarFrom: 2_100,
            roarTo: 520,
            bodyFrequency: 210,
            gurgleCentre: 880,
            gurgleSwing: 150,
            hissFrom: 3_000,
            hissTo: 4_400,
            valveFrequency: 190
        ),
        palette: Palette.chrome
    )

    /// Vacuum assisted. There is no water, and there is no down.
    static let orbital = Fixture(
        id: "orbital",
        name: "Orbital Vacuum",
        blurb: "In space, everyone can hear it.",
        unlockAt: 1_000,
        tolerance: 1.45,
        payout: 0.85,        // Forgiving, and priced like it.
        symbol: "moon.stars.fill",
        surface: .bulkhead,
        profile: FlushProfile(
            duration: 3.0,
            restingLevel: 0.30,
            surgePeak: 0.60,
            spinPeak: 3_200,
            rumbleScale: 0.8,
            chop: 0.006,
            clunkFrequency: 220,
            roarFrom: 3_400,
            roarTo: 240,
            bodyFrequency: 280,
            gurgleCentre: 1_400,
            gurgleSwing: 600,
            hissFrom: 4_200,
            hissTo: 6_000,
            valveFrequency: 300
        ),
        palette: Palette.orbital
    )
}
