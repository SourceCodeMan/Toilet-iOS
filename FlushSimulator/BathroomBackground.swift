import SwiftUI

/// Tiles. It felt wrong to put a toilet on a plain gradient.
struct BathroomBackground: View {
    var palette: Palette

    var body: some View {
        ZStack {
            LinearGradient(colors: [palette.roomTop, palette.roomBottom],
                           startPoint: .top, endPoint: .bottom)

            Canvas { context, size in
                let spacing: CGFloat = 46
                var grout = Path()

                var y: CGFloat = 0
                while y <= size.height {
                    grout.move(to: CGPoint(x: 0, y: y))
                    grout.addLine(to: CGPoint(x: size.width, y: y))
                    y += spacing
                }

                var x: CGFloat = 0
                while x <= size.width {
                    grout.move(to: CGPoint(x: x, y: 0))
                    grout.addLine(to: CGPoint(x: x, y: size.height))
                    x += spacing
                }

                context.stroke(grout, with: .color(palette.tile), lineWidth: 1.5)
            }
        }
    }
}
