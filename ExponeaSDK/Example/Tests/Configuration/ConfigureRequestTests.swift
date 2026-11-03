import XCTest
@testable import Example

final class ConfigureRequestTests: XCTestCase {

    private let missingFields = NSLocalizedString("config.error.missingFields", comment: "")
    private let jwtPair = NSLocalizedString("config.error.jwtPair", comment: "")
    private let invalidUrl = NSLocalizedString("config.error.invalidUrl", comment: "")

    private func request(
        mode: IntegrationMode = .project,
        baseUrl: String = "https://api.exponea.com",
        projectToken: String = "token",
        authToken: String = "Token key",
        streamId: String = "",
        jwtKeyId: String = "",
        jwtSecret: String = ""
    ) -> ConfigureRequest {
        .trimmed(
            mode: mode,
            baseUrl: baseUrl,
            projectToken: projectToken,
            authToken: authToken,
            streamId: streamId,
            jwtKeyId: jwtKeyId,
            jwtSecret: jwtSecret
        )
    }

    func testValidProjectAndStream() {
        XCTAssertNil(request().validationError)
        XCTAssertTrue(request().isValid)
        let stream = request(mode: .stream, projectToken: "", authToken: "", streamId: "stream")
        XCTAssertNil(stream.validationError)
        XCTAssertTrue(stream.isValid)
    }

    func testProjectRequiresTokens() {
        for invalid in [request(projectToken: ""), request(authToken: ""), request(projectToken: "  ")] {
            XCTAssertEqual(invalid.validationError, missingFields)
            XCTAssertFalse(invalid.isValid)
        }
    }

    func testStreamRequiresStreamId() {
        let invalid = request(mode: .stream, streamId: " \n")
        XCTAssertEqual(invalid.validationError, missingFields)
        XCTAssertFalse(invalid.isValid)
    }

    func testJwtKeyIdAndSecretGoTogether() {
        for mode in IntegrationMode.allCases {
            let base = request(mode: mode, streamId: "stream")
            XCTAssertNil(request(mode: mode, streamId: "stream", jwtKeyId: "kid", jwtSecret: "secret").validationError)
            XCTAssertEqual(request(mode: mode, streamId: "stream", jwtKeyId: "kid").validationError, jwtPair)
            XCTAssertEqual(request(mode: mode, streamId: "stream", jwtSecret: "secret").validationError, jwtPair)
            XCTAssertNil(base.validationError)
        }
    }

    func testBaseUrlMustBeHttpWithHost() {
        for baseUrl in ["", "api.exponea.com", "ftp://api.exponea.com", "https://"] {
            let invalid = request(baseUrl: baseUrl)
            XCTAssertEqual(invalid.validationError, invalidUrl, baseUrl)
            XCTAssertFalse(invalid.isValid, baseUrl)
        }
        XCTAssertNil(request(baseUrl: "http://localhost:8080").validationError)
    }

    func testFieldsAreTrimmed() {
        let trimmed = request(
            baseUrl: " https://api.exponea.com\n",
            projectToken: " token ",
            authToken: "\tToken key ",
            streamId: " stream ",
            jwtKeyId: " kid ",
            jwtSecret: " secret\n"
        )
        XCTAssertEqual(trimmed.baseUrl, "https://api.exponea.com")
        XCTAssertEqual(trimmed.projectToken, "token")
        XCTAssertEqual(trimmed.authToken, "Token key")
        XCTAssertEqual(trimmed.streamId, "stream")
        XCTAssertEqual(trimmed.jwtKeyId, "kid")
        XCTAssertEqual(trimmed.jwtSecret, "secret")
    }
}
