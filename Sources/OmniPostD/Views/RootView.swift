import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case composer = "Composer"
    case queue = "Queue"
    case settings = "Settings"

    var id: String { rawValue }
}

struct RootView: View {
    @State private var selection: AppSection? = .dashboard

    var body: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: $selection) { section in
                Text(section.rawValue)
                    .font(.headline)
                    .padding(.vertical, 4)
            }
            .navigationSplitViewColumnWidth(min: 190, ideal: 220)
        } detail: {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                switch selection ?? .dashboard {
                case .dashboard:
                    DashboardView()
                case .composer:
                    ComposerView()
                case .queue:
                    QueueView()
                case .settings:
                    SettingsView()
                }
            }
            .padding(20)
        }
    }
}
