import XCTest
@testable import Example

final class DeeplinkActionTests: XCTestCase {

    private func resolve(_ string: String) -> DeeplinkAction? {
        DeeplinkAction.resolve(URL(string: string)!)
    }

    func testCustomSchemeOpensScreens() {
        XCTAssertEqual(resolve("exponea://track"), .open(.tracking))
        XCTAssertEqual(resolve("exponea://flush"), .open(.flushing))
        XCTAssertEqual(resolve("exponea://fetch"), .open(.fetching))
        XCTAssertEqual(resolve("exponea://inappcb"), .open(.contentBlocks))
        XCTAssertEqual(resolve("exponea://anonymize"), .open(.anonymize))
    }

    func testCustomSchemeMatchesHostOrPathInAnyCase() {
        XCTAssertEqual(resolve("EXPONEA://Flush"), .open(.flushing))
        XCTAssertEqual(resolve("exponea://open/InAppCB"), .open(.contentBlocks))
    }

    func testUniversalLinksOnlyOnAppHost() {
        XCTAssertEqual(resolve("https://mobile-sdk-example-apps.web.app/flush"), .open(.flushing))
        XCTAssertEqual(resolve("http://mobile-sdk-example-apps.web.app/track"), .open(.tracking))
        XCTAssertNil(resolve("https://www.bloomreach.com/flush"))
        XCTAssertNil(resolve("ftp://mobile-sdk-example-apps.web.app/flush"))
    }

    func testStopActionsWinOverScreens() {
        XCTAssertEqual(resolve("exponea://stopandcontinue/track"), .stopAndContinue)
        XCTAssertEqual(resolve("https://mobile-sdk-example-apps.web.app/flush/stopAndRestart"), .stopAndRestart)
    }

    func testUnknownLink() {
        XCTAssertNil(resolve("exponea://settings"))
    }
}
