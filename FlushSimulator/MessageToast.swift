import SwiftUI

/// The app's running commentary.
struct MessageToast: View {
    var message: FlushEngine.Message
    var palette: Palette

    var body: some View {
        HStack(spacing: 8) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .bold))
            }
            Text(message.text)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 18)
        .padding(.vertical, 11)
        .background(
            Capsule(style: .continuous)
                .fill(background)
                .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 24)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var symbol: String? {
        switch message.kind {
        case .golden:    return "sparkles"
        case .unlock:    return "lock.open.fill"
        case .milestone: return "flag.checkered"
        case .busy:      return "hourglass"
        case .quip:      return nil
        }
    }

    private var background: Color {
        switch message.kind {
        case .golden:    return Color(red: 0.99, green: 0.80, blue: 0.22)
        case .unlock:    return Color(red: 0.22, green: 0.62, blue: 0.38)
        case .milestone: return palette.accent
        case .busy:      return palette.porcelainShadow.opacity(0.85)
        case .quip:      return palette.ink.opacity(0.88)
        }
    }

    private var foreground: Color {
        message.kind == .golden ? Color(red: 0.30, green: 0.20, blue: 0.01) : Color.white
    }
}
