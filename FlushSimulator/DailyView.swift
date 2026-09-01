import SwiftUI

/// Today's puzzle: what it asks for, how it went, and something to paste at people.
struct DailyView: View {

    @ObservedObject var engine: FlushEngine
    var palette: Palette
    @Environment(\.dismiss) private var dismiss

    private var challenge: DailyChallenge { engine.challenge }

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                header

                if let run = engine.daily, run.isComplete {
                    grid(run)
                    score(run)
                    ShareLink(item: run.shareText(for: challenge)) {
                        Label("Share result", systemImage: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Capsule().fill(palette.accent))
                            .foregroundStyle(.white)
                    }
                    Text("A new one tomorrow.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                } else if let run = engine.daily {
                    grid(run)
                    score(run)
                    Text("Flush \(run.marks.count + 1) of \(DailyChallenge.flushCount). Close this and pull the handle.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    setup
                    Button {
                        engine.startDaily()
                        dismiss()
                    } label: {
                        Text("Play today's")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Capsule().fill(palette.accent))
                            .foregroundStyle(.white)
                    }
                    Text("One attempt. Everyone gets the same bowl.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 26)
            .padding(.top, 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(palette.roomBottom.opacity(0.30).ignoresSafeArea())
            .navigationTitle("Daily Flush")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("#\(challenge.number)")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .monospacedDigit()
            Text(challenge.fixture.name)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .opacity(0.7)
        }
    }

    /// What the day hands you, before you touch anything.
    private var setup: some View {
        VStack(spacing: 12) {
            row("Toilet", challenge.fixture.name, "toilet.fill")
            row("Paper", "\(challenge.paperTarget) square\(challenge.paperTarget == 1 ? "" : "s") exactly",
                "square.stack.3d.up.fill")
            row("Bowl", "\(Int(challenge.startingGrime * 100))% dirty to start", "drop.triangle.fill")
            row("Flushes", "\(DailyChallenge.flushCount)", "arrow.triangle.2.circlepath")
        }
        .padding(16)
        // Tinted from ink, not porcelain: the sheet inherits whichever fixture is
        // equipped, and a porcelain card under a dark palette's light ink is
        // unreadable. Ink-on-ink holds contrast either way.
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(palette.ink.opacity(0.10)))
    }

    private func row(_ title: String, _ value: String, _ symbol: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
                .frame(width: 20)
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .opacity(0.6)
            Spacer(minLength: 8)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .multilineTextAlignment(.trailing)
        }
        .foregroundStyle(palette.ink)
    }

    /// The run so far, as the squares that get shared.
    private func grid(_ run: DailyResult) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<DailyChallenge.flushCount, id: \.self) { i in
                Text(i < run.marks.count ? run.marks[i].emoji : "▫️")
                    .font(.system(size: 30))
                    .opacity(i < run.marks.count ? 1 : 0.35)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(run.marks.count) of \(DailyChallenge.flushCount) flushes done")
    }

    private func score(_ run: DailyResult) -> some View {
        VStack(spacing: 2) {
            Text(run.score.formatted())
                .font(.system(size: 40, weight: .black, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
            Text("POINTS")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .kerning(0.8)
                .opacity(0.55)
        }
        .foregroundStyle(palette.ink)
    }
}
