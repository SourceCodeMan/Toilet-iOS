import SwiftUI

/// Paper going in, filth coming out — and the plunger, when it all goes wrong.
///
/// One strip that swaps its whole contents while the bowl is blocked, because when
/// it is blocked there is exactly one thing worth doing.
struct UpkeepBar: View {

    @Binding var paper: Int
    var grime: Double
    var isFlushing: Bool
    var isClogged: Bool
    var plunges: Int
    var palette: Palette
    var onWand: () -> Void
    var onPlunge: () -> Void

    var body: some View {
        Group {
            if isClogged { plunger } else { normal }
        }
        .frame(height: 40)
        .animation(.snappy, value: isClogged)
    }

    // MARK: - Blocked

    private var plunger: some View {
        Button(action: onPlunge) {
            HStack(spacing: 9) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 15, weight: .bold))
                Text("PLUNGE")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .kerning(0.5)

                HStack(spacing: 4) {
                    ForEach(0..<Upkeep.plungesToClear, id: \.self) { i in
                        Circle()
                            .fill(i < plunges ? Color.white : Color.white.opacity(0.32))
                            .frame(width: 7, height: 7)
                    }
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(
                Capsule(style: .continuous)
                    .fill(Color(red: 0.86, green: 0.34, blue: 0.24))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Plunge")
        .accessibilityValue("\(plunges) of \(Upkeep.plungesToClear)")
    }

    // MARK: - Business as usual

    private var normal: some View {
        HStack(spacing: 10) {
            paperPicker
            Spacer(minLength: 4)
            wand
        }
    }

    private var paperPicker: some View {
        HStack(spacing: 8) {
            Button { step(-1) } label: { pill("minus") }
                .buttonStyle(.plain)
                .disabled(paper <= Upkeep.paperRange.lowerBound)

            VStack(spacing: 1) {
                Text("\(paper)")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                Text(paper == 1 ? "SQUARE" : "SQUARES")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .opacity(0.55)
            }
            .foregroundStyle(palette.ink)
            .frame(width: 58)

            Button { step(1) } label: { pill("plus") }
                .buttonStyle(.plain)
                .disabled(paper >= Upkeep.paperRange.upperBound)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Toilet paper")
        .accessibilityValue("\(paper) squares. ×\(String(format: "%.1f", Upkeep.multiplier(forPaper: paper))) score.")
        .accessibilityAdjustableAction { step($0 == .increment ? 1 : -1) }
    }

    private func pill(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(palette.ink.opacity(0.75))
            .frame(width: 32, height: 32)
            .background(Circle().fill(palette.ink.opacity(0.09)))
    }

    private func step(_ by: Int) {
        let next = paper + by
        guard Upkeep.paperRange.contains(next) else { return }
        withAnimation(.snappy) { paper = next }
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
