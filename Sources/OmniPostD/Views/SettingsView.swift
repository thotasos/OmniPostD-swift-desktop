import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Settings")
                    .font(.system(size: 30, weight: .bold, design: .rounded))

                VStack(alignment: .leading, spacing: 10) {
                    Text("Connected Accounts")
                        .font(.headline)

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
                                    store.disconnect(accountID: account.id)
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
                                    store.connect(platform: platform.id)
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
                    Text("OmniPostD stores account metadata and post history locally on this Mac. OAuth and live publishing are simulated in this desktop replica build.")
                        .foregroundStyle(.secondary)
                }
                .glassCard()
            }
        }
    }
}
