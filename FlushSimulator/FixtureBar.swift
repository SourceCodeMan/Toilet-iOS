import SwiftUI

/// The row of toilets you own, plus a hint of the next one.
///
/// Locked fixtures stay visible on purpose — the point of a collection is knowing
/// what you have not got yet.
struct FixtureBar: View {

    var fixtures: [Fixture]
    var equipped: Fixture
    var totalFlushes: Int
    var palette: Palette
    var onPick: (Fixture) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(fixtures) { fixture in
                        chip(for: fixture).id(fixture.id)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
            // Otherwise installing something off the end of the row leaves the bar
            // looking like nothing is selected at all.
            .onAppear { proxy.scrollTo(equipped.id, anchor: .center) }
            .onChange(of: equipped) { _, new in
                withAnimation(.snappy) { proxy.scrollTo(new.id, anchor: .center) }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        // Pin the height. A horizontal ScrollView is greedy vertically, and next to
        // the stage's `maxHeight: .infinity` it can end up with almost no hittable
        // box even though the chips still draw.
        .frame(height: 38)
    }

    private func chip(for fixture: Fixture) -> some View {
        let locked = totalFlushes < fixture.unlockAt
        let isOn = fixture == equipped

        return Button {
            guard !locked else { return }
            onPick(fixture)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: locked ? "lock.fill" : fixture.symbol)
                    .font(.system(size: 11, weight: .bold))
                Text(locked ? "\(fixture.unlockAt)" : fixture.name)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                // The payout is the whole reason to pick one over another, so it has
                // to be on the chip rather than buried in a blurb.
                if !locked {
                    Text("×\(fixture.payout, specifier: "%.2g")")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .opacity(isOn ? 0.9 : 0.55)
                }
            }
            .foregroundStyle(isOn ? Color.white : palette.ink.opacity(locked ? 0.35 : 0.75))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(isOn ? palette.accent : palette.ink.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
        .disabled(locked)
        .accessibilityLabel(locked
            ? "\(fixture.name), locked. \(fixture.unlockAt) flushes to unlock."
            : "\(fixture.name), pays \(String(format: "%.2g", fixture.payout)) times")
        .accessibilityHint(locked ? "" : fixture.blurb)
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
    }
}
