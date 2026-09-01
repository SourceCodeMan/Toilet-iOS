import SwiftUI

/// The room the toilet is standing in.
///
/// A wall, a floor, and a horizon between them, so the fixture reads as sitting on
/// something rather than hovering against a flat backdrop. The floor recedes to a
/// vanishing point directly behind the toilet, which is what sells the depth: the
/// shadow alone was never going to.
///
/// Every fixture brings its own surface, drawn in that fixture's own palette, so
/// the outhouse gets boards and the Victorian gets gilt without either needing a
/// colour of its own.
struct BathroomBackground: View {

    var palette: Palette
    var surface: RoomSurface

    /// Where the toilet's feet actually land, in this view's own space. Nil falls back
    /// to `horizon`, which is only right if nothing above has been rescaled.
    var floorY: CGFloat?

    /// Where the floor meets the wall, as a fraction of height.
    ///
    /// Tuned against the toilet's base rather than the middle of the screen. This
    /// view ignores the safe area, so it is taller than the screen and the fraction
    /// lands lower than it reads — hence a number that looks high.
    private let horizon: CGFloat = 0.605

    var body: some View {
        Canvas { context, size in
            // Measured beats tuned: a hand-picked fraction stops being the floor the
            // moment anything above it changes scale.
            let y = min(max(floorY ?? size.height * horizon, size.height * 0.25),
                        size.height * 0.92)
            let wall = CGRect(x: 0, y: 0, width: size.width, height: y)
            let floor = CGRect(x: 0, y: y, width: size.width, height: size.height - y)

            // Wall, lit from above.
            context.fill(Path(wall), with: .linearGradient(
                Gradient(colors: [palette.roomTop, palette.roomBottom]),
                startPoint: .zero, endPoint: CGPoint(x: 0, y: y)))

            // Floor: the room's own colour, shaded down where it meets the wall so
            // the corner reads as a corner.
            context.fill(Path(floor), with: .color(palette.roomBottom))
            context.fill(Path(floor), with: .linearGradient(
                Gradient(colors: [.black.opacity(0.28), .black.opacity(0.04)]),
                startPoint: CGPoint(x: 0, y: y), endPoint: CGPoint(x: 0, y: size.height)))

            drawWall(&context, size: size, horizonY: y)
            drawFloor(&context, size: size, horizonY: y)

            // Fade the boards out as they come toward the viewer. Perspective loses
            // contrast with proximity anyway, and the controls sit down there.
            context.fill(Path(floor), with: .linearGradient(
                Gradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: palette.roomBottom.opacity(0.55), location: 0.42),
                    .init(color: palette.roomBottom.opacity(0.90), location: 1)
                ]),
                startPoint: CGPoint(x: 0, y: y), endPoint: CGPoint(x: 0, y: size.height)))

            // The skirting board, and the shadow the wall casts onto the floor.
            var skirting = Path()
            skirting.move(to: CGPoint(x: 0, y: y))
            skirting.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(skirting, with: .color(palette.porcelainShadow.opacity(0.32)),
                           lineWidth: 2)

            context.fill(
                Path(CGRect(x: 0, y: y, width: size.width, height: 26)),
                with: .linearGradient(
                    Gradient(colors: [palette.porcelainShadow.opacity(0.22), .clear]),
                    startPoint: CGPoint(x: 0, y: y), endPoint: CGPoint(x: 0, y: y + 26)))
        }
    }

    // MARK: - Walls

    private func drawWall(_ context: inout GraphicsContext, size: CGSize, horizonY: CGFloat) {
        switch surface {
        case .tile:     tiledWall(&context, size: size, horizonY: horizonY)
        case .planks:   plankWall(&context, size: size, horizonY: horizonY)
        case .ornate:   ornateWall(&context, size: size, horizonY: horizonY)
        case .panels:   panelWall(&context, size: size, horizonY: horizonY)
        case .bulkhead: bulkheadWall(&context, size: size, horizonY: horizonY)
        }
    }

    /// Square tiles and grout. The original.
    private func tiledWall(_ context: inout GraphicsContext, size: CGSize, horizonY: CGFloat) {
        let spacing: CGFloat = 46
        var grout = Path()
        var y: CGFloat = 0
        while y <= horizonY {
            grout.move(to: CGPoint(x: 0, y: y))
            grout.addLine(to: CGPoint(x: size.width, y: y))
            y += spacing
        }
        var x: CGFloat = 0
        while x <= size.width {
            grout.move(to: CGPoint(x: x, y: 0))
            grout.addLine(to: CGPoint(x: x, y: horizonY))
            x += spacing
        }
        context.stroke(grout, with: .color(palette.tile), lineWidth: 1.5)
    }

    /// Upright boards with a knot or two. Gaps between them, because it is an outhouse.
    private func plankWall(_ context: inout GraphicsContext, size: CGSize, horizonY: CGFloat) {
        let width: CGFloat = 38
        var x: CGFloat = 0
        var board = 0
        while x <= size.width {
            // Alternate boards sit very slightly proud of their neighbours.
            let tone = board % 2 == 0 ? 0.05 : 0.10
            context.fill(Path(CGRect(x: x, y: 0, width: width - 3, height: horizonY)),
                         with: .color(.black.opacity(tone)))

            var seam = Path()
            seam.move(to: CGPoint(x: x + width - 3, y: 0))
            seam.addLine(to: CGPoint(x: x + width - 3, y: horizonY))
            context.stroke(seam, with: .color(.black.opacity(0.26)), lineWidth: 2.5)

            // Grain: a couple of long, lazy arcs per board.
            var grain = Path()
            for k in 1...2 {
                let gy = horizonY * (0.22 * CGFloat(k) + CGFloat(board % 3) * 0.11)
                grain.move(to: CGPoint(x: x + 3, y: gy))
                grain.addQuadCurve(to: CGPoint(x: x + width - 7, y: gy + 5),
                                   control: CGPoint(x: x + width / 2, y: gy - 6))
            }
            context.stroke(grain, with: .color(.black.opacity(0.13)), lineWidth: 1.2)

            x += width
            board += 1
        }
    }

    /// Panelling below a dado rail, gilt stripes above it.
    private func ornateWall(_ context: inout GraphicsContext, size: CGSize, horizonY: CGFloat) {
        let dado = horizonY * 0.58
        let gilt = palette.chromeMid.opacity(0.55)

        // Thin gilt stripes on the upper wall.
        var stripes = Path()
        var x: CGFloat = 22
        while x <= size.width {
            stripes.move(to: CGPoint(x: x, y: 0))
            stripes.addLine(to: CGPoint(x: x, y: dado))
            x += 54
        }
        context.stroke(stripes, with: .color(gilt.opacity(0.30)), lineWidth: 1.2)

        // The rail itself, in two tones so it reads as moulding.
        var rail = Path()
        rail.move(to: CGPoint(x: 0, y: dado))
        rail.addLine(to: CGPoint(x: size.width, y: dado))
        context.stroke(rail, with: .color(gilt), lineWidth: 3)
        var highlight = Path()
        highlight.move(to: CGPoint(x: 0, y: dado - 3))
        highlight.addLine(to: CGPoint(x: size.width, y: dado - 3))
        context.stroke(highlight, with: .color(palette.chromeLight.opacity(0.5)), lineWidth: 1)

        // Raised panels underneath.
        let panelW: CGFloat = 86
        var px: CGFloat = 10
        while px + panelW <= size.width {
            let r = CGRect(x: px, y: dado + 16, width: panelW, height: horizonY - dado - 30)
            context.stroke(Path(roundedRect: r, cornerRadius: 4),
                           with: .color(gilt.opacity(0.45)), lineWidth: 1.6)
            context.stroke(Path(roundedRect: r.insetBy(dx: 7, dy: 7), cornerRadius: 3),
                           with: .color(gilt.opacity(0.22)), lineWidth: 1)
            px += panelW + 12
        }
    }

    /// Wide brushed sheets with recessed seams and a rivet line.
    private func panelWall(_ context: inout GraphicsContext, size: CGSize, horizonY: CGFloat) {
        let band = horizonY / 3
        var seams = Path()
        for i in 1...3 {
            let y = band * CGFloat(i)
            seams.move(to: CGPoint(x: 0, y: y))
            seams.addLine(to: CGPoint(x: size.width, y: y))
        }
        context.stroke(seams, with: .color(palette.chromeDark.opacity(0.30)), lineWidth: 2)

        var shine = Path()
        for i in 1...3 {
            let y = band * CGFloat(i) + 2
            shine.move(to: CGPoint(x: 0, y: y))
            shine.addLine(to: CGPoint(x: size.width, y: y))
        }
        context.stroke(shine, with: .color(palette.chromeLight.opacity(0.35)), lineWidth: 1)

        // Brushing.
        var brush = Path()
        var y: CGFloat = 6
        while y <= horizonY {
            brush.move(to: CGPoint(x: 0, y: y))
            brush.addLine(to: CGPoint(x: size.width, y: y))
            y += 5
        }
        context.stroke(brush, with: .color(.white.opacity(0.035)), lineWidth: 0.7)

        // Rivets along the top seam.
        var rivets = Path()
        var rx: CGFloat = 18
        while rx <= size.width {
            rivets.addEllipse(in: CGRect(x: rx, y: band - 3, width: 4, height: 4))
            rx += 30
        }
        context.fill(rivets, with: .color(palette.chromeDark.opacity(0.35)))
    }

    /// Ribbed hull plating with a lit strip running along it.
    private func bulkheadWall(_ context: inout GraphicsContext, size: CGSize, horizonY: CGFloat) {
        var ribs = Path()
        var x: CGFloat = 0
        while x <= size.width {
            ribs.addRect(CGRect(x: x, y: 0, width: 3, height: horizonY))
            x += 34
        }
        context.fill(ribs, with: .color(.white.opacity(0.045)))

        var rows = Path()
        var y: CGFloat = 58
        while y <= horizonY {
            rows.move(to: CGPoint(x: 0, y: y))
            rows.addLine(to: CGPoint(x: size.width, y: y))
            y += 58
        }
        context.stroke(rows, with: .color(.white.opacity(0.05)), lineWidth: 1)

        // The strip light, and its bloom.
        let lit = horizonY * 0.30
        context.fill(Path(CGRect(x: 0, y: lit, width: size.width, height: 2)),
                     with: .color(palette.accent.opacity(0.75)))
        context.fill(Path(CGRect(x: 0, y: lit - 16, width: size.width, height: 34)),
                     with: .linearGradient(
                        Gradient(colors: [.clear, palette.accent.opacity(0.16), .clear]),
                        startPoint: CGPoint(x: 0, y: lit - 16),
                        endPoint: CGPoint(x: 0, y: lit + 18)))
    }

    // MARK: - Floor

    /// Lines running away to a vanishing point behind the toilet, plus courses that
    /// bunch up as they approach the horizon. That pairing is the whole illusion.
    private func drawFloor(_ context: inout GraphicsContext, size: CGSize, horizonY: CGFloat) {
        let vanishing = CGPoint(x: size.width / 2, y: horizonY)
        let depth = size.height - horizonY
        let ink = floorLine

        var receding = Path()
        for i in -7...7 where i != 0 {
            receding.move(to: vanishing)
            // Spread widens off-screen so the outermost lines still leave the frame.
            receding.addLine(to: CGPoint(x: size.width / 2 + CGFloat(i) * size.width * 0.19,
                                         y: size.height))
        }
        context.stroke(receding, with: .color(ink), lineWidth: 1.2)

        // Courses. Squared spacing bunches them toward the horizon, which is what
        // foreshortening actually looks like.
        var courses = Path()
        var t: CGFloat = 0.08
        while t <= 1.0 {
            let y = horizonY + depth * t * t
            courses.move(to: CGPoint(x: 0, y: y))
            courses.addLine(to: CGPoint(x: size.width, y: y))
            t += 0.13
        }
        context.stroke(courses, with: .color(ink), lineWidth: 1.2)
    }

    // MARK: - Helpers

    private var floorLine: Color {
        switch surface {
        case .tile:     return palette.tile
        case .planks:   return .black.opacity(0.20)
        case .ornate:   return palette.chromeMid.opacity(0.30)
        case .panels:   return palette.chromeDark.opacity(0.22)
        case .bulkhead: return palette.accent.opacity(0.16)
        }
    }
}
