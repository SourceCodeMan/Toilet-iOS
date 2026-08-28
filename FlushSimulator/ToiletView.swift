import SwiftUI

/// The toilet. Drawn at a fixed size and scaled to fit, so the proportions hold
/// on every screen without a single layout calculation.
struct ToiletView: View {

    /// When the current flush started, or nil if the bowl is at rest.
    var flushStart: Date?
    var palette: Palette
    var profile: FlushProfile

    /// How filthy the bowl is, 0...1.
    var grime: Double

    var onPull: (FlushGrade) -> Void

    static let designSize = CGSize(width: 320, height: 470)

    /// How far the finger has pushed the handle, before the flush takes over.
    @State private var drag: Double = 0

    /// When the finger went down, or nil if it is not down. The hold is measured
    /// from here, and the meter reads from the same clock.
    @State private var holdStart: Date?

    var body: some View {
        Group {
            if let flushStart {
                // Every frame, for the three and a half seconds it matters.
                TimelineView(.animation) { timeline in
                    scene(elapsed: timeline.date.timeIntervalSince(flushStart))
                }
            } else {
                // Nothing is moving but the pool, and the pool keeps its own time.
                scene(elapsed: nil)
            }
        }
        .frame(width: Self.designSize.width, height: Self.designSize.height)
        .overlay {
            if let holdStart {
                HoldMeter(holdStart: holdStart, palette: palette)
                    // On the tank face above the lever, in the gap between the lid
                    // and the handle.
                    .position(x: 116, y: 51)
                    .transition(.opacity)
            }
        }
    }

    private func scene(elapsed: Double?) -> some View {
        let level = elapsed.map { FlushTimeline.level(at: $0, profile) } ?? profile.restingLevel
        let spin = elapsed.map { FlushTimeline.spin(at: $0, profile) } ?? 0
        let churn = elapsed.map { FlushTimeline.turbulence(at: $0, profile) } ?? 0
        let shake = elapsed.map { FlushTimeline.rumble(at: $0, profile) } ?? 0
        // Once the flush owns the handle, the finger stops mattering.
        let push = elapsed.map(FlushTimeline.handlePush(at:)) ?? drag

        return ZStack {
            floorShadow
            cistern
            bowl
            seat

            WaterCanvas(level: level, spin: spin, turbulence: churn, flushClock: elapsed,
                        palette: palette, grime: grime)
                .position(x: 160, y: 218)

            handle(push: push, animated: elapsed == nil)
            hitArea
        }
        .frame(width: Self.designSize.width, height: Self.designSize.height)
        .offset(x: shake, y: shake * 0.35)
    }

    // MARK: - Porcelain

    private var porcelain: LinearGradient {
        LinearGradient(colors: [palette.porcelainLight, palette.porcelainMid, palette.porcelainDark],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var chrome: LinearGradient {
        LinearGradient(colors: [palette.chromeLight, palette.chromeMid, palette.chromeDark],
                       startPoint: .top, endPoint: .bottom)
    }

    private var floorShadow: some View {
        Ellipse()
            .fill(palette.porcelainShadow.opacity(0.30))
            .frame(width: 238, height: 30)
            .blur(radius: 10)
            .position(x: 160, y: 438)
    }

    private var cistern: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(porcelain)
                .frame(width: 200, height: 150)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(palette.porcelainLight.opacity(0.85), lineWidth: 1.5)
                )
                .shadow(color: palette.porcelainShadow.opacity(0.32), radius: 10, x: 0, y: 6)
                .position(x: 160, y: 98)

            // A soft glare down one side, which is most of what sells "glazed".
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(palette.porcelainLight.opacity(0.55))
                .frame(width: 14, height: 104)
                .blur(radius: 7)
                .position(x: 228, y: 100)

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(porcelain)
                .frame(width: 218, height: 26)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(palette.porcelainLight.opacity(0.9), lineWidth: 1.5)
                )
                .shadow(color: palette.porcelainShadow.opacity(0.30), radius: 5, x: 0, y: 3)
                .position(x: 160, y: 30)
        }
    }

    private var bowl: some View {
        ZStack {
            BowlShape()
                .fill(porcelain)
                .frame(width: 216, height: 178)
                .shadow(color: palette.porcelainShadow.opacity(0.28), radius: 9, x: 0, y: 6)
                .position(x: 160, y: 297)

            // The foot it stands on.
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(porcelain)
                .frame(width: 174, height: 28)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(palette.porcelainLight.opacity(0.7), lineWidth: 1.2)
                )
                .shadow(color: palette.porcelainShadow.opacity(0.25), radius: 4, x: 0, y: 3)
                .position(x: 160, y: 398)
        }
    }

    private var seat: some View {
        Ellipse()
            .fill(LinearGradient(colors: [palette.porcelainLight, palette.porcelainMid],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 224, height: 102)
            .overlay(Ellipse().strokeBorder(palette.porcelainLight, lineWidth: 1.5))
            .shadow(color: palette.porcelainShadow.opacity(0.38), radius: 7, x: 0, y: 5)
            .position(x: 160, y: 214)
    }

    // MARK: - The only control in the app

    private func handle(push: Double, animated: Bool) -> some View {
        ZStack {
            // Lever. Rotates about its right-hand end, where the pivot sits.
            Capsule()
                .fill(chrome)
                .frame(width: 58, height: 15)
                .overlay(Capsule().strokeBorder(palette.chromeDark.opacity(0.35), lineWidth: 1))
                .shadow(color: .black.opacity(0.22), radius: 3, x: -1, y: 3)
                .rotationEffect(.degrees(10 - 36 * push), anchor: .trailing)
                .position(x: 89, y: 68)

            Circle()
                .fill(chrome)
                .frame(width: 26, height: 26)
                .overlay(Circle().strokeBorder(palette.chromeDark.opacity(0.4), lineWidth: 1))
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
                .position(x: 118, y: 68)

            Circle()
                .fill(palette.chromeDark.opacity(0.45))
                .frame(width: 6, height: 6)
                .position(x: 118, y: 68)
        }
        .animation(animated ? .spring(response: 0.22, dampingFraction: 0.55) : nil, value: push)
    }

    /// A generous target over the handle, because nobody wants to aim.
    private var hitArea: some View {
        Color.clear
            .frame(width: 116, height: 88)
            .contentShape(Rectangle())
            .position(x: 90, y: 68)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        // The lever bottoms out quickly; after that it is all hold.
                        drag = max(0.55, min(0.55 + Double(value.translation.height) / 40, 1))
                        if holdStart == nil {
                            holdStart = Date()
                            Haptics.shared.tick()
                        }
                    }
                    .onEnded { _ in
                        let held = holdStart.map { Date().timeIntervalSince($0) } ?? 0
                        holdStart = nil
                        drag = 0
                        onPull(FlushGrade.grade(forHold: held))
                    }
            )
            .accessibilityElement()
            .accessibilityLabel("Flush handle")
            .accessibilityHint("Hold to flush. Let go inside the window for a perfect flush.")
            .accessibilityAddTraits(.isButton)
            // VoiceOver cannot hold a lever, so it always gets a clean one.
            .accessibilityAction { onPull(.good) }
    }
}
