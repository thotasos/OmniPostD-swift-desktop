import XCTest
@testable import OmniPostD

final class ConnectionRoutingTests: XCTestCase {
    func testYouTubeUsesGoogleOAuthRoute() {
        let route = ConnectionRouting.oauthStartPath(for: .youtube)
        XCTAssertEqual(route.path, "google")
        XCTAssertNil(route.reason)
    }

    func testInstagramIsNotDirectlySupported() {
        let route = ConnectionRouting.oauthStartPath(for: .instagram)
        XCTAssertNil(route.path)
        XCTAssertNotNil(route.reason)
    }

    func testFacebookUsesFacebookRoute() {
        let route = ConnectionRouting.oauthStartPath(for: .facebook)
        XCTAssertEqual(route.path, "facebook")
    }
}
