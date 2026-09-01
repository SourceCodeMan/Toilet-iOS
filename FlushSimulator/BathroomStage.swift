import SwiftUI

/// The room and everything in it you can touch.
///
/// `ToiletView` is still drawn at its own fixed size and knows nothing about any of
/// this; the stage is a wider canvas that places it, hangs the roll on the wall to
/// its left and stands the plunger on the floor to its right. Keeping the toilet's
/// own coordinate space untouched is what makes that cheap — every `.position` in
/// `ToiletView` still means what it always did.
struct BathroomStage: View {

    @ObservedObject var engine: FlushEngine
    var palette: Palette

    /// Where the plunger has been dragged to, relative to its corner.
    @State private var plungerOffset: CGSize = .zero

    static let designSize = CGSize(width: 470, height: 470)

    /// Where the toilet's own 320-wide canvas begins inside this one.
    private static let toiletX = (designSize.width - ToiletView.designSize.width) / 2

    /// The bowl, in stage coordinates. `ToiletView` draws its water at (160, 218).
    private static let bowl = CGPoint(x: toiletX + 160, y: 216)

    /// Where the plunger leans when nothing is blocked.
    private static let plungerHome = CGPoint(x: 410, y: 356)

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Claims the full canvas so the ZStack lays out at 470 wide rather than
            // sizing to the 320-wide toilet. Without it anything positioned past the
            // toilet's edge — the plunger — draws fine but cannot be touched, because
            // hit testing is clipped to the parent's bounds even when drawing is not.
            Color.clear
                .frame(width: Self.designSize.width, height: Self.designSize.height)

            ToiletView(flushStart: engine.flushStart,
                       palette: palette,
                       profile: engine.activeProfile,
                       grime: engine.grime,
                       onPull: { engine.pullHandle($0) })
                .offset(x: Self.toiletX)

            PaperRoll(pulled: engine.paperPulled,
                      isCut: engine.isPaperCut,
                      isTrailing: engine.isPaperTrailing,
                      palette: palette,
                      onPull: { engine.pullPaper(to: $0) },
                      onCut: { engine.cutPaper() })
                .position(x: 54, y: 122)

            Plunger(isClogged: engine.isClogged,
                    plunges: engine.plunges,
                    isBlockedByPaper: engine.isPaperTrailing,
                    palette: palette,
                    bowl: Self.bowl,
                    home: Self.plungerHome,
                    offset: $plungerOffset,
                    onPump: { engine.plunge() })
                .position(x: Self.plungerHome.x + plungerOffset.width,
                          y: Self.plungerHome.y + plungerOffset.height)
        }
        .frame(width: Self.designSize.width, height: Self.designSize.height, alignment: .topLeading)
    }
}
