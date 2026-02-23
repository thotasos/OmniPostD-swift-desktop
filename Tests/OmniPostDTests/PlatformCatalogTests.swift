import XCTest
@testable import OmniPostD

final class PlatformCatalogTests: XCTestCase {
    func testCatalogContainsElevenPlatforms() {
        XCTAssertEqual(PlatformCatalog.all.count, 11)
    }

    func testTwitterCharacterLimitIs280() {
        let twitter = PlatformCatalog.platform(id: .twitter)
        XCTAssertNotNil(twitter)
        XCTAssertEqual(twitter?.characterLimit, 280)
    }

    func testYouTubeSupportsVideoAndLink() {
        let youtube = PlatformCatalog.platform(id: .youtube)
        XCTAssertNotNil(youtube)
        XCTAssertTrue(youtube?.supportedContent.contains(.video) == true)
        XCTAssertTrue(youtube?.supportedContent.contains(.link) == true)
    }
}
