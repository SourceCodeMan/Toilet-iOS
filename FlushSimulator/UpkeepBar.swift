import SwiftUI

/// The wand, and a word about what the bowl needs.
///
/// Paper and the plunger used to live here as a stepper and a big red button. Both
/// are objects in the room now — see `PaperRoll` and `Plunger` — so what is left is
/// the wand, and a line telling you which step of a blockage you are on. Without
/// that line a blocked bowl offers no clue that the plunger on the floor is the
/// answer.
struct UpkeepBar: View {

    var grime: Double
    var isFlushing: Bool
    var isClogged: Bool
    var isPaperTrailing: Bool
    var plunges: Int
    var palette: Palette
    var onWand: () -> Void
    var onPlunge: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            if isClogged { instruction } else { Spacer(minLength: 4) }
            Spacer(minLength: 4)
            wand
        }
        .frame(height: 40)
        .animation(.snappy, value: isClogged)
        .animation(.snappy, value: isPaperTrailing)
    }

    /// What to do next, in the order it has to happen.
    ///
    /// Also tappable as a pump. The plunger on the floor is the intended way to clear
    /// a blockage, but until its drag is reliable this is the guaranteed path — a
    /// blocked bowl with no working way out is a dead end, not a difficulty spike.
    private var instruction: some View {
        Button(action: { if !isPaperTrailing { onPlunge() } }) {
            instructionLabel
        }
        .buttonStyle(.plain)
        .disabled(isPaperTrailing)
    }

    private var instructionLabel: some View {
        HStack(spacing: 7) {
            Image(systemName: isPaperTrailing ? "scissors" : "arrow.down.circle.fill")
                .font(.system(size: 13, weight: .bold))
            Text(isPaperTrailing
                 ? "Swipe across the paper to cut it free"
                 : "Plunge it · \(plunges)/\(Upkeep.plungesToClear)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 13)
        .frame(height: 36)
        .background(Capsule(style: .continuous).fill(Color(red: 0.86, green: 0.34, blue: 0.24)))
        .accessibilityElement(children: .combine)
    }

    /// The wand, with how filthy the bowl is drawn straight into it.
    private var wand: some View {
        Button(action: onWand) {
            HStack(spacing: 7) {
                WandIcon(tint: grime > 0 ? palette.ink : palette.ink.opacity(0.35))

                ZStack(alignment: .leading) {
                    Capsule().fill(palette.ink.opacity(0.14))
                        .frame(width: 46, height: 7)
                    Capsule().fill(grimeColour)
                        .frame(width: max(46 * grime, grime > 0 ? 5 : 0), height: 7)
                }
                .frame(width: 46, height: 7)
            }
            .foregroundStyle(grime > 0 ? palette.ink : palette.ink.opacity(0.35))
            .padding(.horizontal, 13)
            .frame(height: 36)
            .background(Capsule(style: .continuous).fill(palette.ink.opacity(0.09)))
        }
        .buttonStyle(.plain)
        // The engine refuses to scrub mid-flush, so the button should not look live.
        .disabled(grime <= 0 || isFlushing)
        .accessibilityLabel("Potty wand")
        .accessibilityValue(grime <= 0 ? "Bowl is clean" : "\(Int(grime * 100))% dirty")
        .accessibilityHint("Scrubs the bowl. A clean bowl flushes gold more often.")
    }

    private var grimeColour: Color {
        // Clean is the accent, filthy is the colour of something you'd rather not see.
        grime >= Upkeep.grimyAbove
            ? Color(red: 0.48, green: 0.36, blue: 0.14)
            : grime <= Upkeep.cleanBelow ? palette.accent
                                         : Color(red: 0.66, green: 0.55, blue: 0.24)
    }
}
