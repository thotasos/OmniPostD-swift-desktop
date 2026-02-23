import SwiftUI

enum Theme {
    static let backgroundGradient = LinearGradient(
        colors: [Color(red: 0.94, green: 0.98, blue: 1.0), Color(red: 0.96, green: 0.95, blue: 1.0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let card = Color.white.opacity(0.82)

    static func statusColor(_ status: PostStatus) -> Color {
        switch status {
        case .published:
            return .green
        case .failed:
            return .red
        case .publishing:
            return .blue
        case .queued:
            return .orange
        case .draft:
            return .gray
        }
    }

    static func platformColor(_ platform: PlatformID) -> Color {
        switch platform {
        case .facebook: return Color(red: 0.09, green: 0.35, blue: 0.76)
        case .instagram: return Color(red: 0.79, green: 0.22, blue: 0.48)
        case .twitter: return .black
        case .youtube: return Color(red: 0.85, green: 0.1, blue: 0.12)
        case .linkedin: return Color(red: 0.06, green: 0.43, blue: 0.72)
        case .reddit: return Color(red: 0.95, green: 0.33, blue: 0.14)
        case .pinterest: return Color(red: 0.85, green: 0.12, blue: 0.19)
        case .tiktok: return Color(red: 0.1, green: 0.1, blue: 0.1)
        case .tumblr: return Color(red: 0.17, green: 0.27, blue: 0.4)
        case .snapchat: return Color(red: 0.96, green: 0.86, blue: 0.1)
        case .discord: return Color(red: 0.36, green: 0.41, blue: 0.9)
        }
    }
}

struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
            )
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCard())
    }
}
