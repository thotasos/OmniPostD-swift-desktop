import SwiftUI

struct QueueView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Queue")
                    .font(.system(size: 30, weight: .bold, design: .rounded))

                if store.posts.isEmpty {
                    Text("No posts yet")
                        .foregroundStyle(.secondary)
                        .glassCard()
                } else {
                    ForEach(store.posts, id: \.id) { post in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(post.content.isEmpty ? "No content" : post.content)
                                    .lineLimit(2)
                                Spacer()
                                statusChip(post.status)
                            }

                            HStack {
                                ForEach(post.targets, id: \.self) { platform in
                                    attemptChip(post: post, platform: platform)
                                }
                            }

                            if post.attempts.contains(where: { $0.status == .failed }) {
                                Button("Retry Failed Attempts") {
                                    _ = store.retry(postID: post.id)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .glassCard()
                    }
                }
            }
        }
    }

    private func statusChip(_ status: PostStatus) -> some View {
        Text(status.rawValue.capitalized)
            .font(.caption.weight(.bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Theme.statusColor(status).opacity(0.2), in: Capsule())
    }

    private func attemptChip(post: PostDraft, platform: PlatformID) -> some View {
        let attempt = post.attempts.first(where: { $0.platform == platform })
        let color: Color = {
            switch attempt?.status {
            case .success: return .green
            case .failed: return .red
            case .pending: return .orange
            case .none: return .gray
            }
        }()

        return Text(platform.rawValue)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2), in: Capsule())
    }
}
