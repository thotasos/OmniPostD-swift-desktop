import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: AppStore
    @State private var statusMessage = ""
    @State private var alertText = ""
    @State private var showAlert = false
    @State private var callbackInput = ""
    @State private var pendingCallbackPlatform: PlatformID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .foregroundStyle(.secondary)
                        .glassCard()
                }
                connectedAccounts
                quickConnect
                recentPosts
            }
        }
        .alert("OmniPostD", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertText)
        }
        .sheet(item: $pendingCallbackPlatform) { platform in
            VStack(alignment: .leading, spacing: 12) {
                Text("Complete \(platform.rawValue.capitalized) Connection")
                    .font(.headline)
                Text("Paste the full redirected URL from your browser after approving OAuth.")
                    .foregroundStyle(.secondary)
                TextField("https://localhost:8765/callback?code=...", text: $callbackInput)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Button("Cancel") {
                        pendingCallbackPlatform = nil
                        callbackInput = ""
                    }
                    Spacer()
                    Button("Complete") {
                        Task {
                            let message = await store.completeConnection(platform: platform, callbackURL: callbackInput)
                            present(message)
                            pendingCallbackPlatform = nil
                            callbackInput = ""
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(20)
            .frame(width: 640)
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
                        let message = await store.refreshAccounts()
                        present(message)
                    }
                }
                .buttonStyle(.bordered)

                Button("Reset Local Connections") {
                    present(store.resetLocalConnections())
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
                                let message = await store.disconnect(accountID: account.id)
                                present(message)
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
                            let result = await store.connect(platform: platform.id)
                            present(result.message)
                            if result.needsCallback {
                                pendingCallbackPlatform = platform.id
                            }
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

    private func present(_ message: String) {
        statusMessage = message
        alertText = message
        showAlert = true
    }
}
