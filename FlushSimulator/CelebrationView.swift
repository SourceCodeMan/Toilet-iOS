import SwiftUI

/// Falling gold, for the one flush in twenty that earns it.
struct CelebrationView: View {
    var start: Date

    private static let confettiCount = 90
    private static let colors: [Color] = [
        Color(red: 1.00, green: 0.85, blue: 0.30),
        Color(red: 0.98, green: 0.72, blue: 0.10),
        Color(red: 1.00, green: 0.95, blue: 0.70),
        Color(red: 0.86, green: 0.60, blue: 0.05)
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(start)
                guard elapsed > 0 else { return }

                for index in 0..<Self.confettiCount {
                    let lane = hash(index, salt: 1)
                    let pace = 1.9 + hash(index, salt: 2) * 1.3
                    let delay = hash(index, salt: 3) * 0.7
                    let progress = (elapsed - delay) / pace
                    guard progress > 0, progress < 1 else { continue }

                    let sway = sin(elapsed * 3.1 + lane * 12) * 20
                    let x = lane * size.width + sway
                    let y = -24 + progress * (size.height + 48)
                    let width = 5 + hash(index, salt: 4) * 6
                    let height = 8 + hash(index, salt: 5) * 7

                    var flake = context
                    flake.opacity = progress > 0.82 ? (1 - progress) / 0.18 : 1
                    flake.translateBy(x: x, y: y)
                    flake.rotate(by: .degrees(elapsed * 210 + lane * 360))
                    flake.fill(
                        Path(roundedRect: CGRect(x: -width / 2, y: -height / 2, width: width, height: height),
                             cornerRadius: 1.5),
                        with: .color(Self.colors[index % Self.colors.count])
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    private func hash(_ index: Int, salt: Double) -> Double {
        let x = sin(Double(index) * 127.1 + salt * 311.7) * 43_758.5453
        return x - floor(x)
    }
}
