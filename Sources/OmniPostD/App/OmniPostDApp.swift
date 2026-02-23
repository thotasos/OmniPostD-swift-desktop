import SwiftUI

@main
struct OmniPostDApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .frame(minWidth: 980, minHeight: 700)
                .background(Theme.backgroundGradient)
        }
        .windowStyle(.titleBar)
    }
}
