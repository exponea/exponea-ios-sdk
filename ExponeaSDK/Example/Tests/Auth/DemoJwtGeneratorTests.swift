import XCTest
import CryptoKit
@testable import Example

/// The Stream backend rejects tokens that are not HS512 with an `ids` claim, so Stream runs would get 401.
final class DemoJwtGeneratorTests: XCTestCase {

    private func decode(_ part: Substring) throws -> Data {
        var base64 = part.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
        return try XCTUnwrap(Data(base64Encoded: base64))
    }

    private func json(_ part: Substring) throws -> [String: Any] {
        try XCTUnwrap(try JSONSerialization.jsonObject(with: decode(part)) as? [String: Any])
    }

    func testTokenIsSignedHs512WithIdsClaim() throws {
        let ids = ["registered": "user@example.com"]
        let token = try DemoJwtGenerator.generate(keyId: "key-1", secret: " secret ", customerIds: ids)
        let parts = token.split(separator: ".", omittingEmptySubsequences: false)
        XCTAssertEqual(parts.count, 3)

        let header = try json(parts[0])
        XCTAssertEqual(header["alg"] as? String, "HS512")
        XCTAssertEqual(header["typ"] as? String, "JWT")
        XCTAssertEqual(header["kid"] as? String, "key-1")

        let payload = try json(parts[1])
        XCTAssertEqual(payload["ids"] as? [String: String], ids)
        XCTAssertNil(payload["sub"])
        let exp = try XCTUnwrap(payload["exp"] as? Int)
        let expected = Int(Date().timeIntervalSince1970) + 15 * 60
        XCTAssertLessThanOrEqual(abs(exp - expected), 60)

        // The generator trims the secret before signing.
        let key = SymmetricKey(data: Data("secret".utf8))
        let signingInput = Data("\(parts[0]).\(parts[1])".utf8)
        XCTAssertTrue(HMAC<SHA512>.isValidAuthenticationCode(try decode(parts[2]), authenticating: signingInput, using: key))
    }

    func testRejectsMissingIdsAndSecret() {
        XCTAssertThrowsError(try DemoJwtGenerator.generate(keyId: "k", secret: "s", customerIds: [:])) {
            XCTAssertEqual($0 as? DemoJwtGenerator.Error, .missingCustomerIds)
        }
        for secret in ["", "  \n"] {
            XCTAssertThrowsError(try DemoJwtGenerator.generate(keyId: "k", secret: secret, customerIds: ["registered": "a"])) {
                XCTAssertEqual($0 as? DemoJwtGenerator.Error, .invalidSecret)
            }
        }
    }
}
