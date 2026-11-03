import XCTest
@testable import Example

/// Prefill rules for the EXPONEA_* values, as described in the example app README.
final class EnvConfigTests: XCTestCase {

    private func env(
        projectToken: String = "",
        authorizationToken: String = "",
        baseUrl: String = "",
        streamId: String = "",
        integrationMode: String = "",
        autoConfigure: String = ""
    ) -> EnvConfig {
        EnvConfig(
            projectToken: projectToken,
            authorizationToken: authorizationToken,
            baseUrl: baseUrl,
            customerId: "",
            streamId: streamId,
            jwtKeyId: "",
            jwtSecret: "",
            integrationMode: integrationMode,
            autoConfigure: autoConfigure
        )
    }

    func testResolvedMode() {
        XCTAssertEqual(env(integrationMode: "stream").resolvedMode, .stream)
        XCTAssertEqual(env(integrationMode: "Stream").resolvedMode, .stream)
        XCTAssertEqual(env(streamId: "s").resolvedMode, .stream)
        XCTAssertEqual(env(projectToken: "p", streamId: "s").resolvedMode, .project)
        XCTAssertEqual(env(streamId: "s", integrationMode: "project").resolvedMode, .project)
        XCTAssertEqual(env().resolvedMode, .project)
    }

    func testAutoConfigureNeedsCompleteCredentials() {
        let project = env(projectToken: "p", authorizationToken: "a", baseUrl: "https://api.exponea.com")
        XCTAssertTrue(project.shouldAutoConfigure)
        XCTAssertFalse(env(projectToken: "p", baseUrl: "https://api.exponea.com").shouldAutoConfigure)

        let stream = env(baseUrl: "https://api.exponea.com", streamId: "s")
        XCTAssertTrue(stream.shouldAutoConfigure)
        XCTAssertFalse(env(streamId: "s").shouldAutoConfigure)
    }

    func testAutoConfigureCanBeTurnedOff() {
        for value in ["false", "FALSE", "False"] {
            let config = env(baseUrl: "https://api.exponea.com", streamId: "s", autoConfigure: value)
            XCTAssertFalse(config.shouldAutoConfigure, value)
        }
        XCTAssertTrue(env(baseUrl: "https://api.exponea.com", streamId: "s", autoConfigure: "true").shouldAutoConfigure)
    }

    func testPickOrder() {
        XCTAssertEqual(AuthFormPrefill.pick(saved: " saved ", env: "env", default: "default"), "saved")
        XCTAssertEqual(AuthFormPrefill.pick(saved: "  ", env: " env\n", default: "default"), "env")
        XCTAssertEqual(AuthFormPrefill.pick(saved: "", env: " ", default: "default"), "default")
        XCTAssertEqual(AuthFormPrefill.pick(saved: "", env: ""), "")
    }
}
