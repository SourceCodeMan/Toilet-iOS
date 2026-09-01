import SwiftUI

/// The payout card for Benjamin's lucky roll.
///
/// The Easter egg was his idea, so the picture that shows up when it lands is him.
/// Drops in over the gold, holds while the celebration runs, and leaves with it.
struct CashPayoutView: View {

    var palette: Palette
    @State private var landed = false

    var body: some View {
        VStack(spacing: 0) {
            Image("Benjamin")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 220)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(spacing: 2) {
                Text("BENJAMIN'S LUCKY ROLL")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .kerning(1.1)
                Text("one in a hundred")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .opacity(0.7)
            }
            .foregroundStyle(Color(red: 0.30, green: 0.20, blue: 0.01))
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity)
            .background(Color(red: 0.99, green: 0.80, blue: 0.22))
        }
        .frame(width: 236)
        .background(Color(red: 0.99, green: 0.80, blue: 0.22))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.30), radius: 18, x: 0, y: 10)
        .rotationEffect(.degrees(landed ? -3 : 10))
        .scaleEffect(landed ? 1 : 0.7)
        .opacity(landed ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.62)) { landed = true }
        }
        .allowsHitTesting(false)
        .accessibilityElement()
        .accessibilityLabel("Benjamin's lucky roll. One flush in a hundred pays in hundreds.")
    }
}
