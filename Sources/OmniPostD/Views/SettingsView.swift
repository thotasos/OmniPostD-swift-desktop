import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var statusMessage = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Settings")
                    .font(.system(size: 30, weight: .bold, design: .rounded))

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Connected Accounts")
                            .font(.headline)
                        Spacer()
                        Button("Refresh Accounts") {
                            Task {
                                statusMessage = await store.refreshAccounts()
                            }
                        }
                        .buttonStyle(.bordered)
                    }

                    if store.accounts.isEmpty {
                        Text("No connected accounts")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(store.accounts) { account in
                            HStack {
                                Text(account.platform.rawValue.capitalized)
                                Spacer()
                                Text(account.accountName)
                                    .foregroundStyle(.secondary)
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

                VStack(alignment: .leading, spacing: 10) {
                    Text("Add Account")
                        .font(.headline)
                    ForEach(PlatformCatalog.all) { platform in
                        let isConnected = store.connectedPlatformIDs.contains(platform.id)
                        HStack {
                            Text(platform.name)
                            Spacer()
                            if isConnected {
                                Text("Connected")
                                    .foregroundStyle(.secondary)
                            } else {
                                Button("Connect") {
                                    Task {
                                        statusMessage = await store.connect(platform: platform.id)
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Theme.platformColor(platform.id))
                            }
                        }
                    }
                }
                .glassCard()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Security Note")
                        .font(.headline)
                    Text("Connections now use backend OAuth endpoints. Start your Gemini backend on http://localhost:8000, click Connect, complete browser consent, then click Refresh Accounts.")
                        .foregroundStyle(.secondary)
                }
                .glassCard()

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
}
