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

    /// The stage's coordinate space, which stays put while the plunger does not.
    var space: String

    var onPump: () -> Void

    /// How close the rubber has to get to the bowl to count as seated.
    ///
    /// Generous on purpose: the bowl is the only thing worth plunging, so there is
    /// nothing to be precise about, and a tight radius reads as the plunger sitting
    /// in the bowl while refusing to bite.
    private let seatRadius: CGFloat = 105
    /// How far you have to push down for one stroke to register.
    private let strokeTravel: CGFloat = 22

    /// Where it settles when the finger lifts.
    @State private var parked: CGSize = .zero

    /// Where the current downstroke began.
    ///
    /// Held in a reference box rather than `@State` on purpose. A gesture writes this
    /// and reads it back on the very next callback; SwiftUI value state does not
    /// reliably round-trip that fast, so the anchor stayed nil and no stroke ever
    /// completed. A plain object mutation is visible immediately.
    @State private var stroke = Stroke()

    /// The rubber for a given offset. It hangs below the middle of the shape, so
    /// seating is measured from here rather than from the handle.
    private func cup(for offset: CGSize) -> CGPoint {
        CGPoint(x: home.x + offset.width, y: home.y + offset.height + 46)
    }
    private func seated(at offset: CGSize) -> Bool {
        let c = cup(for: offset)
        return hypot(c.x - bowl.x, c.y - bowl.y) < seatRadius
    }
    /// For drawing only. Never use this to decide a stroke mid-gesture: writing the
    /// binding and reading it back in the same `onChanged` can still see the old
    /// value, which reads as "not over the bowl" for the whole drag.
    private var isSeated: Bool { seated(at: offset) }

    var body: some View {
        shape
            // A 12-point handle is not a touch target. The box is what you grab.
            .frame(width: 104, height: 176)
            .contentShape(Rectangle())
            .gesture(haul)
            .opacity(isClogged ? 1 : 0.7)
            // Once the blockage is gone there is nothing to stand in the bowl for.
            // Without this it stays parked on the seat for the rest of the session.
            .onChange(of: isClogged) { _, blocked in
                if !blocked { goHome() }
            }
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
        // Measured in the stage's space, not the plunger's own. Its own space travels
        // with it, which makes both the translation and the stroke read as nothing.
        DragGesture(minimumDistance: 0, coordinateSpace: .named(space))
            .onChanged { value in
                let moved = CGSize(width: parked.width + value.translation.width,
                                   height: parked.height + value.translation.height)
                offset = moved

                // Seating latches. A downstroke pushes the cup well past the bowl's
                // centre, so re-testing every frame unseats it mid-pump and the
                // stroke never completes — and physically, shoving a seated plunger
                // down is the whole point, not a reason for it to pop out.
                if !stroke.seated, seated(at: moved) {
                    stroke.seated = true
                    stroke.restingOffset = moved
                }
                guard isClogged, !isBlockedByPaper, stroke.seated else {
                    stroke.anchor = nil
                    return
                }
                let y = value.location.y
                guard let anchor = stroke.anchor else { stroke.anchor = y; return }

                if y - anchor > strokeTravel {
                    onPump()                 // a completed downstroke
                    stroke.anchor = y
                } else if anchor - y > strokeTravel {
                    stroke.anchor = y        // came back up, ready for the next
                }
            }
            .onEnded { _ in
                // Only an actual blockage earns a place in the bowl, and only if it
                // seated. Anything else goes back to the corner — otherwise a stray
                // drag during ordinary play leaves it standing on the seat.
                if isClogged, stroke.seated {
                    parked = stroke.restingOffset
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                        offset = parked
                    }
                } else {
                    goHome()
                }
                stroke.anchor = nil
                stroke.seated = false
            }
    }

    /// Back to the corner it leans in.
    private func goHome() {
        parked = .zero
        withAnimation(.spring(response: 0.34, dampingFraction: 0.74)) {
            offset = .zero
        }
    }
}

/// A mutable box for the stroke anchor. See the note on `stroke` above.
@MainActor private final class Stroke {
    var anchor: CGFloat?
    /// Set once the cup reaches the bowl, and held for the rest of the drag.
    var seated = false
    /// Where it first sat down, so releasing puts it back there rather than
    /// wherever the last downstroke happened to end.
    var restingOffset: CGSize = .zero
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
