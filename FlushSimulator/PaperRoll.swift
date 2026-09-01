import SwiftUI

/// The roll on the wall, and the sheet you tear off it.
///
/// Paper used to be a stepper you set once and forgot. It is now the thing you do
/// before every flush: draw the sheet down to the length you want, then swipe across
/// to tear it off. Forget the tear and the bowl keeps drawing off the roll for the
/// whole flush — see `FlushEngine.loadedPaper`, which is where that gets expensive.
struct PaperRoll: View {

    /// Squares hanging (or, once torn, sitting ready).
    var pulled: Int
    var isCut: Bool
    /// A flush dragged the roll in and it is still attached.
    var isTrailing: Bool
    /// This one came off as hundreds. One roll in a hundred does.
    var isCash: Bool = false
    var palette: Palette

    var onPull: (Int) -> Void
    var onCut: () -> Void

    static let size = CGSize(width: 96, height: 232)

    /// How far one square hangs, in points.
    private let square: CGFloat = 26
    private let sheetWidth: CGFloat = 46

    /// Squares hanging when the drag began, so a pull is relative rather than absolute.
    @State private var base: Int?
    /// One tear per gesture, however far the finger keeps going.
    @State private var tornThisDrag = false

    private var hanging: Int { isCut ? 0 : pulled }

    /// The green of a bill, rather than the white of a sheet.
    private var billFace: Color { Color(red: 0.42, green: 0.60, blue: 0.44) }
    private var billInk: Color { Color(red: 0.16, green: 0.31, blue: 0.20) }
    private var sheetLength: CGFloat { CGFloat(hanging) * square }

    var body: some View {
        ZStack(alignment: .top) {
            if sheetLength > 0 { sheet }
            holder
            if isCut && pulled > 0 { readyStack }
        }
        .frame(width: Self.size.width, height: Self.size.height, alignment: .top)
        .contentShape(Rectangle())
        .gesture(pullAndTear)
        .animation(.snappy(duration: 0.18), value: pulled)
        .animation(.snappy(duration: 0.18), value: isCut)
        .accessibilityElement()
        .accessibilityLabel("Toilet paper")
        .accessibilityValue(accessibilityState)
        .accessibilityHint("Swipe up or down to pull squares off the roll. Double tap to tear.")
        .accessibilityAdjustableAction { onPull(hanging + ($0 == .increment ? 1 : -1)) }
        .accessibilityAction(named: "Tear off") { onCut() }
    }

    private var accessibilityState: String {
        if isCash { return "\(hanging) hundred dollar bills hanging. Flush them." }
        if isTrailing { return "Caught in the bowl. Tear it free." }
        if isCut { return "\(pulled) squares torn off and ready" }
        return hanging == 0 ? "Nothing pulled yet" : "\(hanging) squares hanging, not torn"
    }

    // MARK: - Drawing

    private var holder: some View {
        ZStack {
            // The bracket it hangs off.
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(LinearGradient(colors: [palette.chromeLight, palette.chromeDark],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 9, height: 34)
                .position(x: Self.size.width / 2 - 34, y: 26)

            // The roll itself.
            Circle()
                .fill(LinearGradient(colors: [.white, palette.porcelainDark],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 54, height: 54)
                .overlay(Circle().strokeBorder(palette.porcelainShadow.opacity(0.25), lineWidth: 1))
                .shadow(color: palette.porcelainShadow.opacity(0.3), radius: 4, x: 0, y: 3)
                .position(x: Self.size.width / 2, y: 32)

            // The cardboard tube.
            Circle()
                .fill(palette.porcelainShadow.opacity(0.35))
                .frame(width: 17, height: 17)
                .position(x: Self.size.width / 2, y: 32)
        }
    }

    /// The sheet hanging off the roll, perforated square by square.
    private var sheet: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(isCash
                      ? LinearGradient(colors: [billFace.opacity(0.95), billFace],
                                       startPoint: .leading, endPoint: .trailing)
                      : LinearGradient(colors: [.white, palette.porcelainMid],
                                       startPoint: .leading, endPoint: .trailing))
                .frame(width: sheetWidth, height: sheetLength)
                .shadow(color: palette.porcelainShadow.opacity(0.22), radius: 3, x: 1, y: 2)

            // Perforations, so the number of squares is countable at a glance.
            ForEach(1..<max(hanging, 1), id: \.self) { i in
                Rectangle()
                    .fill(isCash ? billInk.opacity(0.55) : palette.porcelainShadow.opacity(0.30))
                    .frame(width: sheetWidth - 8, height: 1)
                    .offset(y: CGFloat(i) * square)
            }

            // A hundred on every square, so what is hanging there is unmistakable.
            if isCash {
                ForEach(0..<max(hanging, 1), id: \.self) { i in
                    Text("100")
                        .font(.system(size: 11, weight: .black, design: .serif))
                        .foregroundStyle(billInk)
                        .frame(width: sheetWidth - 10, height: square)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .strokeBorder(billInk.opacity(0.35), lineWidth: 0.8)
                                .padding(2)
                        )
                        .offset(y: CGFloat(i) * square)
                }
            }

            // A torn bottom edge while it is still attached, so "not cut" reads.
            if !isCut {
                Rectangle()
                    .fill(isTrailing ? Color(red: 0.86, green: 0.34, blue: 0.24).opacity(0.55)
                                     : palette.porcelainShadow.opacity(0.28))
                    .frame(width: sheetWidth, height: 2)
                    .offset(y: sheetLength - 1)
            }
        }
        .frame(width: sheetWidth, alignment: .top)
        .offset(y: 52)
    }

    /// Once torn, it sits folded and ready rather than vanishing.
    private var readyStack: some View {
        VStack(spacing: 2) {
            ForEach(0..<min(pulled, 5), id: \.self) { _ in
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(Color.white)
                    .frame(width: 34, height: 4)
                    .shadow(color: palette.porcelainShadow.opacity(0.25), radius: 1, y: 1)
            }
        }
        .padding(.top, 74)
    }

    // MARK: - Pull down, swipe across

    private var pullAndTear: some Gesture {
        DragGesture(minimumDistance: 3)
            .onChanged { value in
                let across = abs(value.translation.width)
                let down = abs(value.translation.height)

                // A decisive sideways swipe tears, but only once per gesture and only
                // when there is something hanging to tear.
                if !tornThisDrag, pulled > 0, across > 34, across > down * 1.3 {
                    tornThisDrag = true
                    onCut()
                    return
                }
                guard !tornThisDrag, !isCut else { return }

                if base == nil { base = hanging }
                let drawn = Int((value.translation.height / square).rounded())
                onPull((base ?? 0) + drawn)
            }
            .onEnded { _ in
                base = nil
                tornThisDrag = false
            }
    }
}
