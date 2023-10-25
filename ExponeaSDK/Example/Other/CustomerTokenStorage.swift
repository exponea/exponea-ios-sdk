//
//  CustomerTokenStorage.swift
//  Example
//
//  Created by Adam Mihalik on 31/01/2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation
import ExponeaSDK

class CustomerTokenStorage {

    public static var shared = CustomerTokenStorage()

    private let semaphore: DispatchQueue = DispatchQueue(
        label: "CustomerTokenStorageLockingQueue",
        attributes: .concurrent
    )

    private var host: String?
    private var projectToken: String?
    private var publicKey: String?
    public private(set) var customerIds: [String: String]?
    private var expiration: Int?

    private var tokenCache: String?

    private var lastTokenRequestTime: Double = 0

    func configure(
        host: String? = nil,
        projectToken: String? = nil,
        publicKey: String? = nil,
        customerIds: [String: String]? = nil,
        expiration: Int? = nil
    ) {
        self.host = host ?? self.host
        self.projectToken = projectToken ?? self.projectToken
        self.publicKey = publicKey ?? self.publicKey
        self.customerIds = customerIds ?? self.customerIds
        self.expiration = expiration ?? self.expiration
    }

    func retrieveJwtToken() -> String? {
        let now = Date().timeIntervalSince1970
        let timeDiffMinutes = abs(now - lastTokenRequestTime) / 60.0
        if timeDiffMinutes < 5 {
            // allows request for token once per 5 minutes, doesn't care if cache is NULL
            return tokenCache
        }
        lastTokenRequestTime = now
        if tokenCache != nil {
            // return cached value
            return tokenCache
        }
        semaphore.sync(flags: .barrier) {
            // recheck nullity just in case
            if tokenCache == nil {
                tokenCache = loadJwtToken()
            }
        }
        return tokenCache
    }

    private func loadJwtToken() -> String? {
        guard let host = self.host,
              let projectToken = self.projectToken,
              let publicKey = self.publicKey,
              let customerIds = self.customerIds,
              customerIds.count > 0 else {
            Exponea.logger.log(.verbose, message: "CustomerTokenStorage not configured yet")
            return nil
        }
        guard let url = URL(safeString: "\(host)/webxp/exampleapp/customertokens") else {
            Exponea.logger.log(.error, message: "Invalid URL host \(host) for CustomerTokenStorage")
            return nil
        }
        var requestBody: [String: Codable] = [
            "project_id": projectToken,
            "kid": publicKey,
            "sub": customerIds
        ]
        if let expiration = expiration {
            requestBody["exp"] = expiration
        }
        do {
            let postData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = postData
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            let httpSemaphore = DispatchSemaphore(value: 0)
            var httpResponseData: Data?
            var httpResponse: URLResponse?
            let httpTask = URLSession.shared.dataTask(with: request) {
                httpResponseData = $0
                httpResponse = $1
                _ = $2
                httpSemaphore.signal()
            }
            httpTask.resume()
            _ = httpSemaphore.wait(timeout: .distantFuture)
            if let httpResponse = httpResponse as? HTTPURLResponse {
                // this is optional check - we looking for 404 posibility
                switch httpResponse.statusCode {
                case 404:
                    // that is fine, only some BE has this endpoint
                    return nil
                case 300..<599:
                    Exponea.logger.log(
                        .error,
                        message: "Example token receiver returns \(httpResponse.statusCode)"
                    )
                    return nil
                default:
                    break
                }
            }
            guard let httpResponseData = httpResponseData else {
                Exponea.logger.log(.error, message: "Example token response is empty")
                return nil
            }
            let responseData = try JSONDecoder().decode(TokenResponse.self, from: httpResponseData)
            if responseData.token == nil {
                Exponea.logger.log(.error, message: "Example token received NULL")
            }
            return responseData.token
        } catch let error {
            Exponea.logger.log(.error, message: "Example token cannot be parsed due error \(error.localizedDescription)")
            return nil
        }
    }
}

struct TokenResponse: Codable {
    var token: String?
    var expiration: Int?

    enum CodingKeys: String, CodingKey {
        case token = "customer_token"
        case expiration = "expire_time"
    }
}
