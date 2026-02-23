import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case composer = "Composer"
    case queue = "Queue"
    case settings = "Settings"

    var id: String { rawValue }
}

struct RootView: View {
    @State private var selection: AppSection = .dashboard

    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 8) {
                Text("OmniPost")
                    .font(.title2.weight(.bold))
                    .padding(.bottom, 6)
                Text("Control Center")
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 12)

                ForEach(AppSection.allCases) { section in
                    Button {
                        selection = section
                    } label: {
                        Text(section.rawValue)
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(selection == section ? Color.accentColor.opacity(0.18) : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .animation(.spring(duration: 0.2), value: selection)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .navigationSplitViewColumnWidth(min: 190, ideal: 220)
        } detail: {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                switch selection {
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
