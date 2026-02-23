import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var statusMessage = ""
    @State private var alertText = ""
    @State private var showAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Settings")
                    .font(.system(size: 30, weight: .bold, design: .rounded))

                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .foregroundStyle(.secondary)
                        .glassCard()
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Connected Accounts")
                            .font(.headline)
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

                        Button("Disconnect All (Backend)") {
                            Task {
                                let message = await store.disconnectAllBackendConnections()
                                present(message)
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
                                        let message = await store.connect(platform: platform.id)
                                        present(message)
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
            }
        }
        .alert("OmniPostD", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertText)
        }
        .task {
            statusMessage = await store.refreshAccounts()
        }
    }

    private func present(_ message: String) {
        statusMessage = message
        alertText = message
        showAlert = true
    }
}
