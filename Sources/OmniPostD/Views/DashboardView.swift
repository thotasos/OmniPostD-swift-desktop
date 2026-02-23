import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: AppStore
    @State private var statusMessage = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                connectedAccounts
                quickConnect
                recentPosts
                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .foregroundStyle(.secondary)
                        .glassCard()
                }
            }
        }
        .task {
            statusMessage = await store.refreshAccounts()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("OmniPost")
                .font(.system(size: 34, weight: .bold, design: .rounded))
            Text("Control Center")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private var connectedAccounts: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Connected Accounts")
                    .font(.title3.bold())
                Spacer()
                Button("Refresh Accounts") {
                    Task {
                        statusMessage = await store.refreshAccounts()
                    }
                }
                .buttonStyle(.bordered)
            }

            if store.accounts.isEmpty {
                Text("No accounts connected yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(store.accounts) { account in
                    HStack {
                        Circle()
                            .fill(Theme.platformColor(account.platform))
                            .frame(width: 12, height: 12)
                        Text(account.platform.rawValue.capitalized)
                            .fontWeight(.semibold)
                        Text(account.accountName)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Disconnect") {
                            Task {
                                statusMessage = await store.disconnect(accountID: account.id)
                            }
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
        .glassCard()
    }

    private var quickConnect: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connect Accounts")
                .font(.title3.bold())
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 10)], spacing: 10) {
                ForEach(PlatformCatalog.all) { platform in
                    let isConnected = store.connectedPlatformIDs.contains(platform.id)
                    Button(platform.name) {
                        Task {
                            statusMessage = await store.connect(platform: platform.id)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.platformColor(platform.id))
                    .disabled(isConnected)
                }
            }
        }
        .glassCard()
    }

    private var recentPosts: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Posts")
                .font(.title3.bold())

            if store.posts.isEmpty {
                Text("No posts yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(store.posts.prefix(5), id: \.id) { post in
                    HStack(alignment: .top) {
                        Text(post.content.isEmpty ? "No content" : post.content)
                            .lineLimit(2)
                        Spacer()
                        Text(post.status.rawValue.capitalized)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Theme.statusColor(post.status).opacity(0.2), in: Capsule())
                    }
                }
            }
        }
        .glassCard()
    }
}
