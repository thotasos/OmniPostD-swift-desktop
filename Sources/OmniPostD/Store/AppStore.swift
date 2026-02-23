import Foundation

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
    private let oauth = StandaloneOAuthService()
    private var pendingOAuth: [PlatformID: OAuthPending] = [:]
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

    func connect(platform: PlatformID) async -> (message: String, needsCallback: Bool) {
        do {
            let start = try oauth.beginConnection(for: platform)
            if let pending = start.pending {
                pendingOAuth[platform] = pending
            }
            return (start.message, start.requiresCallbackPaste)
        } catch let error as StandaloneOAuthError {
            return ("Connection failed: \(error.message)", false)
        } catch {
            return ("Connection failed: \(error.localizedDescription)", false)
        }
    }

    func completeConnection(platform: PlatformID, callbackURL: String) async -> String {
        guard let pending = pendingOAuth[platform] else {
            return "No pending OAuth session for \(platform.rawValue). Start connect again."
        }

        do {
            let profile = try await oauth.finishConnection(platform: platform, callbackURLString: callbackURL, pending: pending)
            pendingOAuth.removeValue(forKey: platform)

            if let index = accounts.firstIndex(where: { $0.platform == platform }) {
                accounts[index].accountName = profile.accountName
                accounts[index].isActive = true
            } else {
                accounts.append(SocialAccount(id: UUID(), platform: platform, accountName: profile.accountName, isActive: true, createdAt: Date()))
            }

            accounts.sort { $0.platform.rawValue < $1.platform.rawValue }
            persist()
            return "Connected \(platform.rawValue.capitalized) as \(profile.accountName)."
        } catch let error as StandaloneOAuthError {
            return "Connection finalize failed: \(error.message)"
        } catch {
            return "Connection finalize failed: \(error.localizedDescription)"
        }
    }

    func refreshAccounts() async -> String {
        persist()
        return "Standalone mode: local account state is current."
    }

    func disconnect(accountID: UUID) async -> String {
        accounts.removeAll { $0.id == accountID }
        persist()
        return "Account disconnected locally."
    }

    func resetLocalConnections() -> String {
        accounts = []
        persist()
        return "Local connection state reset."
    }

    func disconnectAllBackendConnections() async -> String {
        accounts = []
        persist()
        return "Standalone mode: all local connections removed."
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
