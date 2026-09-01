import SwiftUI

/// The plunger, which lives on the floor rather than appearing as a button.
///
/// Drag it over the bowl and it seats; push down from there and each stroke is a
/// pump. Let go anywhere else and it walks back to its corner. The old red PLUNGE
/// button did the same job in one tap, which is exactly why it was not worth doing.
///
/// The stage owns the offset and does the positioning, so this view is a plain sized
/// box with a gesture on it. That matters: a gesture attached after `.position` binds
/// to a parent-filling view rather than to the box you can see, and never fires.
struct Plunger: View {

    var isClogged: Bool
    var plunges: Int
    /// A trailing sheet has to be torn free before this can bite.
    var isBlockedByPaper: Bool
    var palette: Palette

    /// Where the bowl sits, in the stage's coordinate space.
    var bowl: CGPoint
    /// Where it leans when it is not needed.
    var home: CGPoint

    /// Where it has been dragged to, relative to `home`. Owned by the stage.
    @Binding var offset: CGSize

    var onPump: () -> Void

    /// How close the rubber has to get to the bowl to count as seated.
    private let seatRadius: CGFloat = 70
    /// How far you have to push down for one stroke to register.
    private let strokeTravel: CGFloat = 22

    /// Where it settles when the finger lifts.
    @State private var parked: CGSize = .zero
    /// Where the current downstroke began.
    @State private var strokeAnchor: CGFloat?

    /// The rubber itself, which is what has to be over the bowl — it hangs below the
    /// middle of the shape, so seating is measured from here, not from the handle.
    private var cup: CGPoint {
        CGPoint(x: home.x + offset.width, y: home.y + offset.height + 46)
    }
    private var isSeated: Bool {
        hypot(cup.x - bowl.x, cup.y - bowl.y) < seatRadius
    }

    var body: some View {
        shape
            // A 12-point handle is not a touch target. The box is what you grab.
            .frame(width: 104, height: 176)
            .contentShape(Rectangle())
            .gesture(haul)
            .opacity(isClogged ? 1 : 0.7)
            .accessibilityElement()
            .accessibilityLabel("Plunger")
            .accessibilityValue(isClogged
                ? (isBlockedByPaper ? "Blocked by paper still attached"
                                    : "\(plunges) of \(Upkeep.plungesToClear) pumps")
                : "Not needed right now")
            .accessibilityHint("Drag onto the bowl, then push down to plunge.")
            .accessibilityAction(named: "Pump") { onPump() }
    }

    // MARK: - Drawing

    private var shape: some View {
        VStack(spacing: -3) {
            Capsule()
                .fill(LinearGradient(colors: [Color(red: 0.72, green: 0.53, blue: 0.32),
                                              Color(red: 0.46, green: 0.31, blue: 0.16)],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(width: 12, height: 92)
                .shadow(color: .black.opacity(0.22), radius: 3, x: 1, y: 2)

            PlungerCup()
                .fill(LinearGradient(colors: [Color(red: 0.78, green: 0.22, blue: 0.18),
                                              Color(red: 0.44, green: 0.09, blue: 0.07)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 46, height: 40)
                .shadow(color: .black.opacity(0.28), radius: 4, x: 0, y: 3)
        }
        // Seated and biting: it sinks a little, so the pump reads.
        .scaleEffect(isSeated && isClogged ? 1.05 : 1, anchor: .bottom)
    }

    // MARK: - Haul it over, then push

    private var haul: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                offset = CGSize(width: parked.width + value.translation.width,
                                height: parked.height + value.translation.height)

                guard isClogged, !isBlockedByPaper, isSeated else {
                    strokeAnchor = nil
                    return
                }
                let y = value.location.y
                guard let anchor = strokeAnchor else { strokeAnchor = y; return }

                if y - anchor > strokeTravel {
                    onPump()                 // a completed downstroke
                    strokeAnchor = y
                } else if anchor - y > strokeTravel {
                    strokeAnchor = y         // came back up, ready for the next
                }
            }
            .onEnded { _ in
                // Stay where it was put if it is over the bowl; otherwise walk home.
                parked = isSeated ? offset : .zero
                withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                    offset = parked
                }
                strokeAnchor = nil
            }
    }
}

/// A bell-shaped rubber cup: wide flared lip, narrow neck.
private struct PlungerCup: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: w * 0.34, y: 0))
        p.addLine(to: CGPoint(x: w * 0.66, y: 0))
        p.addCurve(to: CGPoint(x: w, y: h * 0.82),
                   control1: CGPoint(x: w * 0.80, y: h * 0.18),
                   control2: CGPoint(x: w * 0.99, y: h * 0.46))
        p.addQuadCurve(to: CGPoint(x: 0, y: h * 0.82),
                       control: CGPoint(x: w * 0.5, y: h * 1.16))
        p.addCurve(to: CGPoint(x: w * 0.34, y: 0),
                   control1: CGPoint(x: w * 0.01, y: h * 0.46),
                   control2: CGPoint(x: w * 0.20, y: h * 0.18))
        p.closeSubpath()
        return p.offsetBy(dx: rect.minX, dy: rect.minY)
    }
}
