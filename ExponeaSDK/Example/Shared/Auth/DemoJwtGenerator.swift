import Foundation
import CryptoKit
import ExponeaSDK

// ⚠️ DEMO ONLY — mints Stream JWTs in the app from the key ID and secret entered on the configuration screen.
// Production apps MUST mint tokens on a secure backend; never ship signing secrets in the app.
enum DemoJwtGenerator {

    private static let defaultExpirationMinutes = 15
    private static let algorithmName = "HS512"

    enum Error: Swift.Error, LocalizedError {
        case invalidSecret
        case encodingFailed
        case missingCustomerIds

        var errorDescription: String? {
            switch self {
            case .invalidSecret:       return "JWT secret could not be encoded."
            case .encodingFailed:      return "JWT header/payload encoding failed."
            case .missingCustomerIds:  return "JWT payload requires non-empty customer ids."
            }
        }
    }

    /// Generates a signed HS512 JWT with `ids` + `exp` claims.
    static func generate(
        keyId: String,
        secret: String,
        customerIds: [String: String],
        expirationMinutes: Int = defaultExpirationMinutes
    ) throws -> String {
        guard !customerIds.isEmpty else { throw Error.missingCustomerIds }

        let trimmedSecret = secret.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSecret.isEmpty,
              let secretData = trimmedSecret.data(using: .utf8) else {
            throw Error.invalidSecret
        }

        let expiresAt = Date().addingTimeInterval(TimeInterval(expirationMinutes * 60))
        let exp = Int(expiresAt.timeIntervalSince1970)

        let headerDict: [String: String] = [
            "typ": "JWT",
            "alg": algorithmName,
            "kid": keyId
        ]
        let payloadDict: [String: Any] = [
            "exp": exp,
            "ids": customerIds
        ]

        guard
            let headerData = try? JSONSerialization.data(withJSONObject: headerDict),
            let payloadData = try? JSONSerialization.data(withJSONObject: payloadDict)
        else {
            throw Error.encodingFailed
        }

        let encodedHeader = base64URLEncode(headerData)
        let encodedPayload = base64URLEncode(payloadData)
        let signingInput = "\(encodedHeader).\(encodedPayload)"

        guard let signingInputData = signingInput.data(using: .utf8) else {
            throw Error.encodingFailed
        }

        let key = SymmetricKey(data: secretData)
        let signature = HMAC<SHA512>.authenticationCode(for: signingInputData, using: key)
        let token = "\(signingInput).\(base64URLEncode(Data(signature)))"

        Exponea.logger.log(
            .verbose,
            message: "DemoJwtGenerator: token generated, expires at \(expiresAt), ids: \(customerIds.keys.sorted())"
        )
        return token
    }

    private static func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

// MARK: - Demo JWT session

enum DemoJwtSession {
    private static var keyId: String?
    private static var secret: String?

    static var isConfigured: Bool {
        guard let keyId, let secret else { return false }
        return !keyId.isEmpty && !secret.isEmpty
    }

    static func configure(keyId: String, secret: String) {
        let trimmedKey = keyId.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSecret = secret.trimmingCharacters(in: .whitespacesAndNewlines)
        self.keyId = trimmedKey.isEmpty ? nil : trimmedKey
        self.secret = trimmedSecret.isEmpty ? nil : trimmedSecret
        if isConfigured {
            Exponea.logger.log(.verbose, message: "DemoJwtSession configured")
        }
    }

    static func clear() {
        keyId = nil
        secret = nil
    }

    static func generateToken(customerIds: [String: String]) -> String? {
        guard isConfigured, let keyId, let secret else {
            Exponea.logger.log(.warning, message: "DemoJwtSession: secret or kid not configured, skipping token generation.")
            return nil
        }
        guard !customerIds.isEmpty else {
            Exponea.logger.log(.warning, message: "DemoJwtSession: token without customer IDs would not be valid, skipping generation.")
            return nil
        }
        return try? DemoJwtGenerator.generate(
            keyId: keyId,
            secret: secret,
            customerIds: customerIds
        )
    }
}

/// Reactive Stream JWT refresh for the example app (demo-only).
enum StreamAuthListener {
    private static var fallbackCustomerIds: [String: String] = [:]

    static var isActive: Bool { DemoJwtSession.isConfigured }

    static func prepare(keyId: String, secret: String, customerIds: [String: String]) {
        DemoJwtSession.configure(keyId: keyId, secret: secret)
        fallbackCustomerIds = customerIds
    }

    static func registerHandlerIfNeeded() {
        guard DemoJwtSession.isConfigured else { return }
        Exponea.shared.setJwtErrorHandler { context in
            Exponea.logger.log(.warning, message: "JWT Error: reason=\(context.reason)")
            let ids = context.customerIds ?? fallbackCustomerIds
            guard !ids.isEmpty else {
                Exponea.logger.log(.warning, message: "JWT token needs refresh but customer ids are missing")
                return
            }
            guard let token = DemoJwtSession.generateToken(customerIds: ids) else { return }
            Exponea.shared.setSdkAuthToken(token)
            Exponea.logger.log(.verbose, message: "JWT refreshed via DemoJwtSession and set via setSdkAuthToken")
        }
    }

    static func initialToken(customerIds: [String: String]) -> String? {
        DemoJwtSession.generateToken(customerIds: customerIds)
    }

    static func stop() {
        DemoJwtSession.clear()
        fallbackCustomerIds = [:]
    }
}
