import Foundation

struct PublishingService {
    func publish(post: inout PostDraft, connectedPlatformIDs: Set<PlatformID>) -> PublishResult {
        guard !post.targets.isEmpty else {
            post.status = .failed
            return PublishResult(success: false, attempts: [])
        }

        post.status = .publishing
        var attempts: [PostAttempt] = []

        for platform in post.targets {
            attempts.append(executeAttempt(platform: platform, post: post, connectedPlatformIDs: connectedPlatformIDs))
        }

        post.attempts = attempts
        let anySuccess = attempts.contains(where: { $0.status == .success })
        post.status = anySuccess ? .published : .failed
        if anySuccess {
            post.publishedAt = Date()
        }
        return PublishResult(success: anySuccess, attempts: attempts)
    }

    func retryFailedAttempts(post: inout PostDraft, connectedPlatformIDs: Set<PlatformID>) -> PublishResult {
        var attempts = post.attempts
        let failedIndices = attempts.indices.filter { attempts[$0].status == .failed }

        for idx in failedIndices {
            let platform = attempts[idx].platform
            attempts[idx] = executeAttempt(platform: platform, post: post, connectedPlatformIDs: connectedPlatformIDs)
        }

        post.attempts = attempts
        let anySuccess = attempts.contains(where: { $0.status == .success })
        post.status = anySuccess ? .published : .failed
        if anySuccess {
            post.publishedAt = Date()
        }

        return PublishResult(success: anySuccess, attempts: failedIndices.map { attempts[$0] })
    }

    private func executeAttempt(platform: PlatformID, post: PostDraft, connectedPlatformIDs: Set<PlatformID>) -> PostAttempt {
        guard connectedPlatformIDs.contains(platform) else {
            return PostAttempt(platform: platform, status: .failed, errorMessage: "No connected \(platform.rawValue) account")
        }

        let content = post.overrides[platform] ?? post.content
        if content.lowercased().contains("force_fail") {
            return PostAttempt(platform: platform, status: .failed, errorMessage: "Simulated platform failure")
        }

        return PostAttempt(platform: platform, status: .success, errorMessage: nil)
    }
}
