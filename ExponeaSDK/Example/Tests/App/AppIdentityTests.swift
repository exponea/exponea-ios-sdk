import XCTest
@testable import Example

/// test-hub, Bitrise and universal links depend on these values.
final class AppIdentityTests: XCTestCase {

    func testBundleValues() throws {
        let info = try XCTUnwrap(Bundle.main.infoDictionary)
        XCTAssertEqual(Bundle.main.bundleIdentifier, "com.exponea.sdk.example")
        XCTAssertEqual(info["CFBundleDisplayName"] as? String, "Bloomreach SDK Demo")

        let urlTypes = try XCTUnwrap(info["CFBundleURLTypes"] as? [[String: Any]])
        let schemes = try XCTUnwrap(urlTypes.first?["CFBundleURLSchemes"] as? [String])
        XCTAssertEqual(schemes.first, "exponea")
    }

    /// The SDK looks this protocol up (BuildConfigurationShared.isCalledFromExampleApp) to send the example
    /// app's telemetry to the dev Sentry project instead of the production one.
    func testExampleAppMarker() {
        XCTAssertNotNil(NSProtocolFromString("IsExponeaExampleApp"))
    }

    /// The Example scheme's Test action sets EXPONEA_AUTO_CONFIGURE=false and ignores the Run environment,
    /// so the host app never configures the real SDK while the tests run. Checks the setting itself, because
    /// `shouldAutoConfigure` is also false when no credentials are set.
    func testHostAppDoesNotAutoConfigure() {
        XCTAssertEqual(
            EnvConfig.load().autoConfigure.lowercased(), "false",
            "Example scheme Test action must set EXPONEA_AUTO_CONFIGURE=false"
        )
    }

    func testEntitlements() throws {
        let url = try XCTUnwrap(
            Bundle(for: Self.self).url(forResource: "Example", withExtension: "entitlements"),
            "Example.entitlements is not a resource of the test bundle"
        )
        let plist = try PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil)
        let entitlements = try XCTUnwrap(plist as? [String: Any])

        let appGroups = try XCTUnwrap(entitlements["com.apple.security.application-groups"] as? [String])
        XCTAssertEqual(appGroups.first, "group.com.exponea.sdk.example")
        XCTAssertEqual(ExampleConstants.appGroup, appGroups.first)

        let domains = try XCTUnwrap(entitlements["com.apple.developer.associated-domains"] as? [String])
        XCTAssertEqual(domains.first, "applinks:\(DeeplinkAction.appLinkHost)")
    }
}
