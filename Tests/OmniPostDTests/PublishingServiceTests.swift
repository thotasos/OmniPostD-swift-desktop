import XCTest
@testable import OmniPostD

final class PublishingServiceTests: XCTestCase {
    func testPublishingWithoutTargetsFailsPost() {
        var post = PostDraft(content: "Hello", mediaPaths: [], overrides: [:], targets: [])
        let result = PublishingService().publish(post: &post, connectedPlatformIDs: [])

        XCTAssertFalse(result.success)
        XCTAssertEqual(post.status, .failed)
    }

    func testPublishingCreatesAttemptPerTargetAndPublishesWhenAnySuccess() {
        var post = PostDraft(content: "Ship", mediaPaths: [], overrides: [:], targets: [.facebook, .twitter])
        let result = PublishingService().publish(post: &post, connectedPlatformIDs: [.facebook, .twitter])

        XCTAssertEqual(result.attempts.count, 2)
        XCTAssertEqual(post.attempts.count, 2)
        XCTAssertEqual(post.status, .published)
    }

    func testRetryOnlyRetriesFailedAttempts() {
        var post = PostDraft(content: "Retry", mediaPaths: [], overrides: [:], targets: [.instagram])
        post.attempts = [PostAttempt(platform: .instagram, status: .failed, errorMessage: "Temporary")]
        post.status = .failed

        let result = PublishingService().retryFailedAttempts(post: &post, connectedPlatformIDs: [.instagram])

        XCTAssertEqual(result.attempts.count, 1)
        XCTAssertNotEqual(post.attempts.first?.status, .failed)
    }
}
