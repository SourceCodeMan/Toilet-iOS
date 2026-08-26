import SwiftUI

/// Everything inside the rim: the dry porcelain, the pool, the vortex and the foam.
///
/// Drawn in a `Canvas` rather than stacked shapes because the swirl is a spiral
/// sampled every frame, and because clipping a dozen layers to the same ellipse
/// gets expensive fast.
struct WaterCanvas: View {

    /// 0 = drained, 1 = brimming.
    var level: Double
    /// Total rotation of the water so far, in degrees.
    var spin: Double
    /// 0 = still, 1 = churning.
    var turbulence: Double
    /// Seconds since the flush began, or nil when the bowl is at rest.
    var flushClock: Double?
    var palette: Palette

    static let size = CGSize(width: 178, height: 68)

    var body: some View {
        if let flushClock {
            canvas(clock: flushClock)
        } else {
            // At rest only the pool needs a clock, and twelve frames a second is
            // plenty for a shimmer. The porcelain around it stays static.
            TimelineView(.periodic(from: .now, by: 1.0 / 12.0)) { timeline in
                canvas(clock: timeline.date.timeIntervalSinceReferenceDate)
            }
        }
    }

    private func canvas(clock: Double) -> some View {
        Canvas(opaque: false, rendersAsynchronously: false) { context, size in
            let rim = CGRect(origin: .zero, size: size)
            context.clip(to: Path(ellipseIn: rim))

            drawDryBowl(in: &context, rim: rim)
            let pool = surfaceRect(in: rim, clock: clock)
            drawWater(in: &context, pool: pool)

            if turbulence > 0.01 {
                drawVortex(in: &context, pool: pool)
                drawBubbles(in: &context, pool: pool, clock: clock)
            }

            drawHighlights(in: &context, pool: pool, rim: rim)
        }
        .frame(width: Self.size.width, height: Self.size.height)
    }

    // MARK: - Layers

    private func drawDryBowl(in context: inout GraphicsContext, rim: CGRect) {
        context.fill(
            Path(ellipseIn: rim),
            with: .linearGradient(
                Gradient(colors: [palette.porcelainMid, palette.porcelainDark]),
                startPoint: CGPoint(x: rim.midX, y: rim.minY),
                endPoint: CGPoint(x: rim.midX, y: rim.maxY)
            )
        )
    }

    private func surfaceRect(in rim: CGRect, clock: Double) -> CGRect {
        // A breath of movement even at rest, so the pool never looks like a sticker.
        let shimmer = sin(clock * 1.7) * 0.006
        let l = min(max(level + shimmer, 0), 1)
        let width = rim.width * (0.46 + 0.54 * l)
        let height = rim.height * (0.34 + 0.66 * l)
        let centreY = rim.midY + (1 - l) * rim.height * 0.18
        return CGRect(x: rim.midX - width / 2, y: centreY - height / 2, width: width, height: height)
    }

    private func drawWater(in context: inout GraphicsContext, pool: CGRect) {
        context.fill(
            Path(ellipseIn: pool),
            with: .linearGradient(
                Gradient(colors: [palette.waterLight, palette.waterDark]),
                startPoint: CGPoint(x: pool.midX, y: pool.minY),
                endPoint: CGPoint(x: pool.midX, y: pool.maxY)
            )
        )
    }

    private func drawVortex(in context: inout GraphicsContext, pool: CGRect) {
        var swirl = context
        swirl.clip(to: Path(ellipseIn: pool))

        let centre = CGPoint(x: pool.midX, y: pool.midY)
        let rx = pool.width / 2
        let ry = pool.height / 2
        let phase = spin * .pi / 180

        for arm in 0..<3 {
            var path = Path()
            let offset = phase + Double(arm) * (2 * .pi / 3)
            let steps = 46
            for step in 0...steps {
                let u = Double(step) / Double(steps)          // 0 at the rim, 1 at the drain
                let theta = offset + u * 3.4 * .pi
                let radius = 1 - u * 0.94
                let point = CGPoint(x: centre.x + cos(theta) * rx * radius,
                                    y: centre.y + sin(theta) * ry * radius)
                if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            swirl.stroke(path,
                         with: .color(palette.foam.opacity(0.40 * turbulence)),
                         style: StrokeStyle(lineWidth: 3.0, lineCap: .round, lineJoin: .round))
        }

        // The hole it all disappears into.
        let coreRadius = 10 * turbulence
        if coreRadius > 0.5 {
            let core = CGRect(x: centre.x - coreRadius, y: centre.y - coreRadius * 0.42,
                              width: coreRadius * 2, height: coreRadius * 0.84)
            swirl.fill(Path(ellipseIn: core), with: .color(palette.waterDark.opacity(0.85)))
        }
    }

    private func drawBubbles(in context: inout GraphicsContext, pool: CGRect, clock: Double) {
        var foam = context
        foam.clip(to: Path(ellipseIn: pool))

        let centre = CGPoint(x: pool.midX, y: pool.midY)
        let rx = pool.width / 2
        let ry = pool.height / 2
        let phase = spin * .pi / 180

        for index in 0..<18 {
            let seed = hash(index)
            let speed = 0.5 + seed * 0.55
            let travel = fract(clock * speed + seed)             // rim to drain, then round again
            let radius = (1 - travel) * 0.92
            let theta = phase * (0.7 + seed * 0.5) + seed * 2 * .pi
            let dot = (1.1 + seed * 2.3) * (0.35 + 0.65 * turbulence)
            let point = CGPoint(x: centre.x + cos(theta) * rx * radius,
                                y: centre.y + sin(theta) * ry * radius)
            let rect = CGRect(x: point.x - dot, y: point.y - dot, width: dot * 2, height: dot * 2)
            foam.fill(Path(ellipseIn: rect),
                      with: .color(palette.foam.opacity(0.8 * turbulence * (1 - travel))))
        }
    }

    private func drawHighlights(in context: inout GraphicsContext, pool: CGRect, rim: CGRect) {
        // Foam collecting at the edge of the pool.
        context.stroke(Path(ellipseIn: pool),
                       with: .color(palette.foam.opacity(0.22 + 0.5 * turbulence)),
                       lineWidth: 1.5)

        // A glint off the surface.
        let glint = CGRect(x: pool.minX + pool.width * 0.17,
                           y: pool.minY + pool.height * 0.14,
                           width: pool.width * 0.30,
                           height: pool.height * 0.15)
        context.fill(Path(ellipseIn: glint), with: .color(.white.opacity(0.30)))

        // Shadow cast by the rim.
        var shade = context
        shade.addFilter(.blur(radius: 3))
        shade.stroke(Path(ellipseIn: rim.insetBy(dx: 2, dy: 2)),
                     with: .color(palette.porcelainShadow.opacity(0.55)),
                     lineWidth: 6)
    }

    // MARK: - Scratch maths

    private func hash(_ index: Int) -> Double {
        fract(sin(Double(index) * 127.1 + 13.7) * 43_758.5453)
    }

    private func fract(_ x: Double) -> Double { x - floor(x) }
}
