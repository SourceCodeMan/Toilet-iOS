import SwiftUI

/// A potty wand.
///
/// Drawn rather than borrowed from SF Symbols, for the same reason the toilet is:
/// nothing in the catalogue reads as a toilet wand. `paintbrush.pointed` was the
/// closest and it looked like decorating.
///
/// The silhouette that sells it is a long thin shaft with a fat, blunt, slightly
/// scalloped head — the opposite of a brush's flat wedge of bristles.
struct WandIcon: View {

    var tint: Color

    var body: some View {
        ZStack {
            // Shaft, with a thumb grip near the top.
            Capsule()
                .fill(tint)
                .frame(width: 2.4, height: 11)
                .offset(y: -5.5)

            Capsule()
                .fill(tint.opacity(0.55))
                .frame(width: 4.2, height: 3)
                .offset(y: -8)

            // Collar where the head clips on.
            Capsule()
                .fill(tint)
                .frame(width: 5.5, height: 2)
                .offset(y: 1.2)

            // The head: blunt and bulbous, not bristled.
            ZStack {
                Ellipse()
                    .fill(tint)
                    .frame(width: 12, height: 9.5)

                // Two scallops, so it reads as a sponge rather than a blob.
                Ellipse()
                    .fill(tint.opacity(0.45))
                    .frame(width: 7, height: 4)
                    .offset(y: -1.4)
            }
            .offset(y: 6.4)
        }
        .frame(width: 16, height: 22)
        .rotationEffect(.degrees(-14))
    }
}
