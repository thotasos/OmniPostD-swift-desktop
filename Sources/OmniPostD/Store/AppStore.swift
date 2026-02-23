import Foundation
import AppKit

struct SocialAccount: Codable, Identifiable, Hashable {
    let id: UUID
    let platform: PlatformID
    var accountName: String
    var isActive: Bool
    var createdAt: Date
}

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var accounts: [SocialAccount] = []
    @Published private(set) var posts: [PostDraft] = []

    private let publisher = PublishingService()
    private let backend = BackendService()
    private let saveURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent("OmniPostD", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        saveURL = directory.appendingPathComponent("store.json")
        load()
    }

    var connectedPlatformIDs: Set<PlatformID> {
        Set(accounts.filter(\.isActive).map(\.platform))
    }

    func connect(platform: PlatformID) async -> String {
        do {
            let authURL = try await backend.startOAuth(platform: platform)
            NSWorkspace.shared.open(authURL)
            return "Browser opened for \(platform.rawValue.capitalized) OAuth. Complete auth, then click Refresh Accounts."
        } catch {
            return "Connection failed: \(friendlyError(error))"
        }
    }

    func refreshAccounts() async -> String {
        do {
            accounts = try await backend.fetchAccounts()
            persist()
            return "Accounts synced from backend."
        } catch {
            return "Failed to refresh accounts: \(friendlyError(error))"
        }
    }

    func disconnect(accountID: UUID) async -> String {
        do {
            try await backend.disconnect(accountID: accountID)
            accounts.removeAll { $0.id == accountID }
            persist()
            return "Account disconnected."
        } catch {
            // Keep the desktop app operable even when backend is unavailable.
            accounts.removeAll { $0.id == accountID }
            persist()
            return "Backend disconnect failed (\(friendlyError(error))). Local connection removed."
        }
    }

    func resetLocalConnections() -> String {
        accounts = []
        persist()
        return "Local connection state reset."
    }

    func disconnectAllBackendConnections() async -> String {
        do {
            let backendAccounts = try await backend.fetchAccounts()
            for account in backendAccounts {
                try await backend.disconnect(accountID: account.id)
            }
            accounts = []
            persist()
            return "All backend connections disconnected."
        } catch {
            return "Failed to disconnect all backend connections: \(friendlyError(error))"
        }
    }

    private func friendlyError(_ error: Error) -> String {
        let text = error.localizedDescription
        if text.contains("Could not connect to the server") || text.contains("Failed to connect") {
            return "Backend is unreachable at http://localhost:8000. Start Gemini backend first."
        }
        if let backend = error as? BackendError {
            return backend.message
        }
        if text.isEmpty {
            return "Unknown error."
        }
        return text
    }

    @discardableResult
    func publishNow(content: String, mediaPaths: [String], overrides: [PlatformID: String], targets: [PlatformID]) -> PublishResult {
        var post = PostDraft(content: content, mediaPaths: mediaPaths, overrides: overrides, targets: targets)
        let result = publisher.publish(post: &post, connectedPlatformIDs: connectedPlatformIDs)
        posts.insert(post, at: 0)
        persist()
        return result
    }

    func queue(content: String, mediaPaths: [String], overrides: [PlatformID: String], targets: [PlatformID]) {
        var post = PostDraft(content: content, mediaPaths: mediaPaths, overrides: overrides, targets: targets)
        post.status = .queued
        posts.insert(post, at: 0)
        persist()
    }

    @discardableResult
    func retry(postID: UUID) -> PublishResult? {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else { return nil }
        var post = posts[index]
        let result = publisher.retryFailedAttempts(post: &post, connectedPlatformIDs: connectedPlatformIDs)
        posts[index] = post
        persist()
        return result
    }

    private func load() {
        guard let data = try? Data(contentsOf: saveURL) else { return }
        guard let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        accounts = snapshot.accounts
        posts = snapshot.posts
    }

    private func persist() {
        let snapshot = Snapshot(accounts: accounts, posts: posts)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: saveURL, options: [.atomic])
    }

    private struct Snapshot: Codable {
        let accounts: [SocialAccount]
        let posts: [PostDraft]
    }
}
