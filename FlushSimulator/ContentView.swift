import SwiftUI

struct ContentView: View {

    @StateObject private var engine = FlushEngine()
    @Environment(\.colorScheme) private var colorScheme
    @State private var isMuted = FlushAudio.shared.isMuted
    @State private var isConfirmingReset = false
    @State private var hintPulse = false

    private var palette: Palette {
        engine.showsGold ? .golden(colorScheme) : .standard(colorScheme)
    }

    var body: some View {
        ZStack {
            BathroomBackground(palette: palette)
                .ignoresSafeArea()

            VStack(spacing: 10) {
                header
                stage
                statsCard
                hint
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 12)

            if let message = engine.message {
                MessageToast(message: message, palette: palette)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 74)
                    .allowsHitTesting(false)
            }

            if let start = engine.celebrationStart {
                CelebrationView(start: start)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: engine.showsGold)
        .task {
            FlushAudio.shared.prepare()
            Haptics.shared.prepare()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                hintPulse = true
            }
        }
        .alert("Erase your flushing legacy?", isPresented: $isConfirmingReset) {
            Button("Erase It All", role: .destructive) { engine.resetStats() }
            Button("Never Mind", role: .cancel) { }
        } message: {
            Text("Every flush, every rank, every golden moment. Gone, like they were never here.")
        }
    }

    // MARK: - Chrome

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 1) {
                Text("FLUSH SIMULATOR")
                    .font(.system(size: 23, weight: .black, design: .rounded))
                    .kerning(1.2)
                Text("2026 Deluxe Porcelain Edition")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .opacity(0.65)
            }
            Spacer(minLength: 8)
            Button {
                isMuted.toggle()
                FlushAudio.shared.isMuted = isMuted
            } label: {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(palette.porcelainLight.opacity(0.55)))
            }
            .accessibilityLabel(isMuted ? "Turn sound on" : "Turn sound off")
        }
        .foregroundStyle(palette.ink)
    }

    private var stage: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width / ToiletView.designSize.width,
                            geometry.size.height / ToiletView.designSize.height)
            ToiletView(flushStart: engine.flushStart,
                       palette: palette,
                       onPull: { engine.pullHandle() })
                .scaleEffect(scale)
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var statsCard: some View {
        let rank = Rank.current(for: engine.totalFlushes)

        return VStack(spacing: 11) {
            HStack(spacing: 0) {
                stat(title: "LIFETIME FLUSHES", value: engine.totalFlushes.formatted())
                Divider().frame(height: 32)
                stat(title: "GOLDEN", value: engine.goldenFlushes.formatted())
            }

            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: rank.symbol)
                        .font(.system(size: 13, weight: .bold))
                    Text(rank.title)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    Spacer(minLength: 6)
                    if let next = Rank.next(after: engine.totalFlushes) {
                        Text("\(next.threshold - engine.totalFlushes) to go")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .opacity(0.6)
                    } else {
                        Text("MAXED OUT")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .opacity(0.6)
                    }
                }
                ProgressView(value: Rank.progress(for: engine.totalFlushes))
                    .progressViewStyle(.linear)
                    .tint(palette.accent)
            }
        }
        .foregroundStyle(palette.ink)
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(palette.porcelainLight.opacity(colorScheme == .dark ? 0.14 : 0.6))
        )
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onLongPressGesture(minimumDuration: 0.9) { isConfirmingReset = true }
        .accessibilityHint("Press and hold to reset your stats")
    }

    private func stat(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 26, weight: .black, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .kerning(0.8)
                .opacity(0.55)
        }
        .frame(maxWidth: .infinity)
    }

    private var hint: some View {
        Text(engine.totalFlushes == 0 ? "Push the handle" : "Tap or drag the handle")
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(palette.ink)
            .opacity(hintPulse ? 0.75 : 0.3)
    }
}

#Preview {
    ContentView()
}
