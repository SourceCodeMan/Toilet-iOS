import SwiftUI

/// What the tank was worth, once it runs dry.
///
/// A run needs an ending or it is just an accumulator with extra steps. This is the
/// moment the score stops moving and you decide whether to go again.
struct RunSummaryView: View {

    var score: Int
    var best: Int
    var bestStreak: Int
    var palette: Palette
    var onAgain: () -> Void

    private var isBest: Bool { score >= best && score > 0 }

    var body: some View {
        VStack(spacing: 20) {
            Text(isBest ? "BEST TANK YET" : "TANK EMPTY")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .kerning(1.4)
                .foregroundStyle(isBest ? palette.accent : palette.ink.opacity(0.55))

            VStack(spacing: 2) {
                Text(score.formatted())
                    .font(.system(size: 60, weight: .black, design: .rounded))
                    .monospacedDigit()
                Text("POINTS")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .kerning(0.8)
                    .opacity(0.55)
            }
            .foregroundStyle(palette.ink)

            HStack(spacing: 0) {
                tally("BEST", best.formatted())
                Divider().frame(height: 30)
                tally("STREAK", bestStreak.formatted())
                Divider().frame(height: 30)
                tally("FLUSHES", "\(Upkeep.runLength)")
            }
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.ink.opacity(0.08)))

            Button(action: onAgain) {
                Text("New tank")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Capsule().fill(palette.accent))
                    .foregroundStyle(.white)
            }
        }
        .padding(26)
        .presentationDetents([.height(380)])
        .presentationBackground(palette.roomBottom.opacity(0.96))
    }

    private func tally(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .monospacedDigit()
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .kerning(0.6)
                .opacity(0.55)
        }
        .foregroundStyle(palette.ink)
        .frame(maxWidth: .infinity)
    }
}
