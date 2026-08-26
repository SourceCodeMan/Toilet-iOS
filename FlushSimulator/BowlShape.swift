import SwiftUI

/// The body of the bowl: a wide rim tucking in to a narrow pedestal.
/// The top edge bulges up because the seat sits over it.
struct BowlShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: 0, y: h * 0.10))
        path.addCurve(to: CGPoint(x: w * 0.23, y: h),
                      control1: CGPoint(x: w * 0.01, y: h * 0.62),
                      control2: CGPoint(x: w * 0.14, y: h * 0.90))
        path.addLine(to: CGPoint(x: w * 0.77, y: h))
        path.addCurve(to: CGPoint(x: w, y: h * 0.10),
                      control1: CGPoint(x: w * 0.86, y: h * 0.90),
                      control2: CGPoint(x: w * 0.99, y: h * 0.62))
        path.addQuadCurve(to: CGPoint(x: 0, y: h * 0.10),
                          control: CGPoint(x: w * 0.5, y: -h * 0.14))
        path.closeSubpath()
        return path.offsetBy(dx: rect.minX, dy: rect.minY)
    }
}
