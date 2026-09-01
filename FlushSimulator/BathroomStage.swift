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

    /// Named so the plunger can measure its drag against something that holds still.
    static let space = "bathroom-stage" 

    /// Where the toilet's own 320-wide canvas begins inside this one.
    private static let toiletX = (designSize.width - ToiletView.designSize.width) / 2

    /// The bowl, in stage coordinates. `ToiletView` draws its water at (160, 218).
    private static let bowl = CGPoint(x: toiletX + 160, y: 216)

    /// Where the plunger leans when nothing is blocked. Its cup wants to land on the
    /// same line the toilet stands on, which is `floorLine` below.
    private static let plungerHome = CGPoint(x: 410, y: 346)

    /// Where the toilet's foot meets the ground, in stage units. `ToiletView` draws
    /// the foot as a 28-tall bar centred on 398, so it ends here.
    static let floorLine: CGFloat = 412

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
                      isCash: engine.isCashRoll,
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
                    space: Self.space,
                    onPump: { engine.plunge() })
                .position(x: Self.plungerHome.x + plungerOffset.width,
                          y: Self.plungerHome.y + plungerOffset.height)
        }
        .frame(width: Self.designSize.width, height: Self.designSize.height, alignment: .topLeading)
        // The plunger measures its drag against this. It must NOT use the gesture's
        // default `.local` space: the plunger moves with the finger, so its own space
        // moves too, translation stays near zero, and it never goes anywhere.
        .coordinateSpace(.named(Self.space))
    }
}
