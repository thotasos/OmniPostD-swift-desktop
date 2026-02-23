import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var statusMessage = ""
    @State private var alertText = ""
    @State private var showAlert = false
    @State private var callbackInput = ""
    @State private var pendingCallbackPlatform: PlatformID?

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
                                        let result = await store.connect(platform: platform.id)
                                        present(result.message)
                                        if result.needsCallback {
                                            pendingCallbackPlatform = platform.id
                                        }
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
                    Text("Standalone OAuth Setup")
                        .font(.headline)
                    Text("Populate client IDs/secrets at ~/Library/Application Support/OmniPostD/oauth_credentials.json. Configure each provider redirect URI to http://localhost:8765/callback.")
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

    private func present(_ message: String) {
        statusMessage = message
        alertText = message
        showAlert = true
    }
}
