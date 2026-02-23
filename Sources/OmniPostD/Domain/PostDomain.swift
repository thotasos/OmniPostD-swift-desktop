import Foundation

enum PostStatus: String, Codable {
    case draft
    case queued
    case publishing
    case published
    case failed
}

enum AttemptStatus: String, Codable, Equatable {
    case pending
    case success
    case failed
}

struct PostAttempt: Codable, Equatable, Identifiable {
    var id = UUID()
    var platform: PlatformID
    var status: AttemptStatus
    var errorMessage: String?
    var attemptedAt = Date()
}

struct PostDraft: Codable {
    var id = UUID()
    var content: String
    var mediaPaths: [String]
    var overrides: [PlatformID: String]
    var targets: [PlatformID]
    var status: PostStatus = .draft
    var createdAt = Date()
    var publishedAt: Date?
    var attempts: [PostAttempt] = []
}

struct PublishResult {
    let success: Bool
    let attempts: [PostAttempt]
}
