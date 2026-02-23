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

    func connect(platform: PlatformID) {
        if let index = accounts.firstIndex(where: { $0.platform == platform }) {
            accounts[index].isActive = true
            persist()
            return
        }

        let account = SocialAccount(
            id: UUID(),
            platform: platform,
            accountName: "\(PlatformCatalog.platform(id: platform)?.name ?? platform.rawValue) Account",
            isActive: true,
            createdAt: Date()
        )
        accounts.append(account)
        accounts.sort { $0.platform.rawValue < $1.platform.rawValue }
        persist()
    }

    func disconnect(accountID: UUID) {
        guard let index = accounts.firstIndex(where: { $0.id == accountID }) else { return }
        accounts.remove(at: index)
        persist()
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
