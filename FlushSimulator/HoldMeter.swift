import SwiftUI

/// The window you are aiming for, while your finger is still down.
///
/// Sits on the tank face just above the handle, where there is about seventeen
/// points to work with — hence the flat layout, with the verdict beside the bar
/// rather than stacked over it.
///
/// Keeps its own clock, so nothing else in the app has to animate to drive it.
struct HoldMeter: View {

    var holdStart: Date
    var palette: Palette

    /// Width of the track itself. The label takes what it needs beside it.
    private let track: Double = 112

    var body: some View {
        TimelineView(.animation) { timeline in
            let held = timeline.date.timeIntervalSince(holdStart)
            let fill = min(held / FlushGrade.meterSpan, 1)
            let grade = FlushGrade.grade(forHold: held)

            HStack(spacing: 7) {
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(palette.ink.opacity(0.16))
                        .frame(width: track, height: 9)

                    // The window, marked out so you can see what you are aiming at.
                    Capsule()
                        .fill(palette.accent.opacity(0.30))
                        .frame(width: track * span, height: 9)
                        .offset(x: track * (FlushGrade.perfectFrom / FlushGrade.meterSpan))

                    Capsule()
                        .fill(colour(for: grade))
                        .frame(width: max(track * fill, 5), height: 9)
                }
                .frame(width: track, height: 9)

                Text(grade == .weak ? "hold" : grade.label)
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(colour(for: grade))
                    .fixedSize()
                    .animation(.easeOut(duration: 0.12), value: grade)
            }
        }
        .frame(height: 12)
        .accessibilityHidden(true)
    }

    private var span: Double {
        (FlushGrade.perfectUntil - FlushGrade.perfectFrom) / FlushGrade.meterSpan
    }

    private func colour(for grade: FlushGrade) -> Color {
        switch grade {
        case .weak:     return palette.ink.opacity(0.45)
        case .good:     return palette.accent
        case .perfect:  return Color(red: 0.16, green: 0.72, blue: 0.44)
        case .overheld: return Color(red: 0.86, green: 0.34, blue: 0.24)
        }
    }
}
