import SwiftUI

/// Your best days, and everyone else's.
struct LeaderboardView: View {

    enum Scope: String, CaseIterable { case local = "Your Days", global = "Global" }

    var standings: Standings
    var lifetime: Int
    var palette: Palette
    @StateObject private var global = GlobalBoard()
    @State private var scope: Scope = .local
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $scope) {
                    ForEach(Scope.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.bottom, 10)

                Group {
                    switch scope {
                    case .local:  localBoard
                    case .global: globalBoard
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.top, 8)
            .background(palette.roomBottom.opacity(0.35).ignoresSafeArea())
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Local

    private var localBoard: some View {
        Group {
            if standings.board.isEmpty {
                empty("No flushes recorded yet.", "Today is a blank slate.")
            } else {
                List {
                    Section {
                        ForEach(Array(standings.board.enumerated()), id: \.element.id) { i, day in
                            row(rank: i + 1,
                                name: Standings.label(for: day.stamp),
                                score: day.flushes,
                                detail: detail(for: day),
                                isYou: day.stamp == Standings.stamp(for: Date()))
                        }
                    } header: {
                        Text(headline)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
    }

    private var headline: String {
        guard let today = standings.today else { return "Best days" }
        if let rank = standings.todaysRank {
            return "Best days — today is #\(rank) with \(today.flushes)"
        }
        return "Best days — today has \(today.flushes) so far"
    }

    private func detail(for day: Standings.Day) -> String {
        var bits: [String] = []
        if day.golden > 0 { bits.append("\(day.golden) golden") }
        if day.bestStreak > 1 { bits.append("×\(day.bestStreak) streak") }
        return bits.joined(separator: " · ")
    }

    // MARK: - Global

    private var globalBoard: some View {
        Group {
            switch global.state {
            case .idle, .working:
                VStack(spacing: 14) {
                    ProgressView()
                    Text("Asking Game Center…")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .opacity(0.7)
                }

            case .signedOut:
                empty("Not signed in to Game Center.",
                      "Sign in from Settings → Game Center to appear on the global board.")

            case .notConfigured:
                empty("The global board isn't live yet.",
                      "It needs a leaderboard created in App Store Connect, which needs the paid membership. Your days are still being recorded.")

            case .failed(let why):
                empty("Game Center didn't answer.", why)

            case .ready(let entries) where entries.isEmpty:
                empty("Nobody has flushed anything yet.", "Be the first.")

            case .ready(let entries):
                List(entries) { e in
                    row(rank: e.rank, name: e.name, score: e.score, detail: "", isYou: e.isYou)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .task(id: scope) {
            guard scope == .global else { return }
            await global.refresh()
            await global.submit(lifetime: lifetime, bestDay: standings.bestDay?.flushes ?? 0)
        }
    }

    // MARK: - Pieces

    private func row(rank: Int, name: String, score: Int, detail: String, isYou: Bool) -> some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(rank <= 3 ? palette.accent : .secondary)
                .frame(width: 24, alignment: .trailing)

            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.system(size: 15, weight: isYou ? .heavy : .semibold, design: .rounded))
                if !detail.isEmpty {
                    Text(detail)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            Text(score.formatted())
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .monospacedDigit()
        }
        .padding(.vertical, 2)
    }

    private func empty(_ title: String, _ note: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
            Text(note)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 34)
    }
}
