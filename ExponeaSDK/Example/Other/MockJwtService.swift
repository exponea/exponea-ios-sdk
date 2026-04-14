import CryptoKit
import Foundation
import ExponeaSDK

/**
 * !!! WARN for developers.
 * This implementation is just proof of concept for the Example App.
 * In production, JWT tokens MUST be generated on a secure backend.
 * Never embed signing secrets in a shipping application.
 */
final class MockJwtService {

    static let shared = MockJwtService()

    private let defaultExpirationMinutes = 15
    private let algorithmName = "HS512"

    private var secret: String?
    private var kid: String?
    private let queue = DispatchQueue(label: "MockJwtService.queue")

    private init() {}

    /// JWT Key ID / secret configuration.
    /// - Parameters:
    ///   - secret: HMAC shared secret for signing. Empty or blank disables the generator.
    ///   - kid: Key ID (`kid` header) identifying the stream signing secret.
    func configure(secret: String, kid: String) {
        queue.sync(flags: .barrier) {
            self.secret = secret.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            self.kid = kid.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        }
        Exponea.logger.log(.verbose, message: "MockJwtService configured!")
    }

    /// Clear stored credentials (e.g. on anonymize / logout).
    func clear() {
        queue.sync(flags: .barrier) {
            self.secret = nil
            self.kid = nil
        }
    }

    /// Returns true if this generator has been configured with a non-empty secret and kid.
    var isConfigured: Bool {
        queue.sync {
            guard let s = secret, let k = kid else { return false }
            return !s.isEmpty && !k.isEmpty
        }
    }

    /// Generates a JWT with the given customer IDs embedded in the `ids` claim.
    ///
    /// Token structure:
    /// - Header: `typ=JWT`, `alg=HS512`, `kid=<configured-key-id>`
    /// - Payload: `exp=<unix-seconds>`, `ids={<id_type>: <id_value>, ...}`
    /// - Signature: HMAC-SHA512 with the configured shared secret
    ///
    /// - Parameter customerIds: Map of trusted IDs (e.g. "registered" to "user@example.com").
    /// - Returns: Signed JWT string, or nil if not configured, customer IDs are empty, or generation fails.
    func generateToken(customerIds: [String: String]) -> String? {
        let credentials: (String, String)? = queue.sync {
            guard let s = secret, let k = kid, !s.isEmpty, !k.isEmpty else { return nil }
            return (s, k)
        }
        guard let (secretVal, kidVal) = credentials else {
            Exponea.logger.log(.warning, message: "MockJwtService: secret or kid not configured, skipping token generation.")
            return nil
        }
        if customerIds.isEmpty {
            Exponea.logger.log(.warning, message: "MockJwtService: token without customer IDs would not be valid, skipping generation.")
            return nil
        }

        let expiresAt = Date().addingTimeInterval(TimeInterval(defaultExpirationMinutes * 60))
        let exp = Int(expiresAt.timeIntervalSince1970)

        let headerDict: [String: String] = [
            "typ": "JWT",
            "alg": algorithmName,
            "kid": kidVal
        ]
        let payloadDict: [String: Any] = [
            "exp": exp,
            "ids": customerIds
        ]

        guard let headerData = try? JSONSerialization.data(withJSONObject: headerDict),
              let payloadData = try? JSONSerialization.data(withJSONObject: payloadDict) else {
            return nil
        }

        let encodedHeader = base64UrlEncode(headerData)
        let encodedPayload = base64UrlEncode(payloadData)
        let signingInput = "\(encodedHeader).\(encodedPayload)"

        guard let signingInputData = signingInput.data(using: .utf8),
              let secretData = secretVal.data(using: .utf8) else {
            return nil
        }

        let key = SymmetricKey(data: secretData)
        let hmac = HMAC<SHA512>.authenticationCode(for: signingInputData, using: key)
        let signatureB64 = base64UrlEncode(Data(hmac))

        let token = "\(signingInput).\(signatureB64)"
        Exponea.logger.log(.verbose, message: "MockJwtService: token generated, expires at \(expiresAt), ids: \(customerIds.keys.sorted()).")
        return token
    }

    private func base64UrlEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
