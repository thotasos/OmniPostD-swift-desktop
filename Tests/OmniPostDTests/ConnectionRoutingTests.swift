import XCTest
@testable import OmniPostD

final class ConnectionRoutingTests: XCTestCase {
    func testInstagramDirectConnectionIsRejected() {
        let service = StandaloneOAuthService()
        XCTAssertThrowsError(try service.beginConnection(for: .instagram)) { error in
            guard let oauthError = error as? StandaloneOAuthError else {
                XCTFail("Expected StandaloneOAuthError")
                return
            }
            switch oauthError {
            case .unsupported(let reason):
                XCTAssertTrue(reason.contains("Facebook"))
            default:
                XCTFail("Expected unsupported error")
            }
        }
    }

    func testTumblrConnectionReportsOAuth1Unsupported() {
        let service = StandaloneOAuthService()
        XCTAssertThrowsError(try service.beginConnection(for: .tumblr)) { error in
            guard let oauthError = error as? StandaloneOAuthError else {
                XCTFail("Expected StandaloneOAuthError")
                return
            }
            switch oauthError {
            case .unsupported(let reason):
                XCTAssertTrue(reason.contains("OAuth1"))
            default:
                XCTFail("Expected unsupported error")
            }
        }
    }
}
