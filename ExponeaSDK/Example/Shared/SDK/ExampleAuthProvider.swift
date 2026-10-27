import Foundation
import ExponeaSDK

/// Authorization provider for "Advanced auth" in Project mode. The SDK finds it by the Objective-C
/// name `ExponeaAuthProvider` and asks it for a customer token before each authorized request.
@objc(ExponeaAuthProvider)
public class ExampleAuthProvider: NSObject, AuthorizationProviderType {
    required public override init() {}

    public func getAuthorizationToken() -> String? {
        CustomerTokenStorage.shared.retrieveJwtToken()
    }

    public func getAuthorizationHeader() -> String? {
        nil
    }
}

/// Fetches customer tokens for the example app from the demo token service
/// (`<base URL>/webxp/exampleapp/customertokens`), cached for 5 minutes. Stream mode does not use it:
/// its JWT is minted locally.
final class CustomerTokenStorage {

    static let shared = CustomerTokenStorage()

    private let queue = DispatchQueue(label: "CustomerTokenStorageQueue")
    private var host: String?
    private var projectToken: String?
    private var publicKey: String?
    private var customerIds: [String: String]?
    private var tokenCache: String?
    private var lastTokenRequestTime: TimeInterval = 0

    /// Only non-nil values replace the stored ones; any change resets the cached token.
    func configure(
        host: String? = nil,
        projectToken: String? = nil,
        publicKey: String? = nil,
        customerIds: [String: String]? = nil
    ) {
        queue.sync {
            self.host = host ?? self.host
            self.projectToken = projectToken ?? self.projectToken
            self.publicKey = publicKey ?? self.publicKey
            self.customerIds = customerIds ?? self.customerIds
            tokenCache = nil
            lastTokenRequestTime = 0
        }
    }

    func retrieveJwtToken() -> String? {
        queue.sync {
            let now = Date().timeIntervalSince1970
            // At most one request per 5 minutes, even when the last one returned no token.
            if tokenCache != nil || now - lastTokenRequestTime < 5 * 60 {
                return tokenCache
            }
            lastTokenRequestTime = now
            tokenCache = loadToken()
            return tokenCache
        }
    }

    private func loadToken() -> String? {
        guard let host, let projectToken, let publicKey, !publicKey.isEmpty,
              let customerIds, !customerIds.isEmpty else {
            log(.verbose, "Customer token storage is not configured yet")
            return nil
        }
        guard let url = URL(string: "\(host)/webxp/exampleapp/customertokens") else {
            log(.error, "Invalid customer token URL for host \(host)")
            return nil
        }
        var request = URLRequest(url: url, timeoutInterval: 10)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "project_id": projectToken,
            "kid": publicKey,
            "sub": customerIds
        ])

        // The SDK calls the provider synchronously, so wait for the response (bounded by the timeout).
        let done = DispatchSemaphore(value: 0)
        var result: (data: Data?, response: URLResponse?) = (nil, nil)
        URLSession.shared.dataTask(with: request) { data, response, _ in
            result = (data, response)
            done.signal()
        }.resume()
        guard done.wait(timeout: .now() + 11) == .success else {
            log(.error, "Customer token request timed out")
            return nil
        }
        if let status = (result.response as? HTTPURLResponse)?.statusCode, status >= 300 {
            // 404: the backend has no demo token service.
            log(status == 404 ? .verbose : .error, "Customer token service returned \(status)")
            return nil
        }
        guard let data = result.data,
              let token = (try? JSONDecoder().decode(CustomerTokenResponse.self, from: data))?.token else {
            log(.error, "Customer token response has no token")
            return nil
        }
        return token
    }

    private func log(_ level: LogLevel, _ message: String) {
        DispatchQueue.main.async { InAppLogStore.shared.append(level: level, message: message) }
    }
}

private struct CustomerTokenResponse: Decodable {
    let token: String?

    enum CodingKeys: String, CodingKey {
        case token = "customer_token"
    }
}
