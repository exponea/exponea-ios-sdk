//
//  RequestFactory.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 09/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// Mutable reference for use in closures.
private final class Ref<T> {
    var value: T
    init(_ value: T) { self.value = value }
}

/// Path route with projectId
public struct RequestFactory {
    let exponeaIntegrationType: any ExponeaIntegrationType
    let route: Routes
    let streamAuthProvider: AuthorizationProviderType?
    let onAuthorizationError: ((String, Int, Data?) -> Void)?

    public init(
        exponeaIntegrationType: any ExponeaIntegrationType,
        route: Routes,
        streamAuthProvider: AuthorizationProviderType? = nil,
        onAuthorizationError: ((String, Int, Data?) -> Void)? = nil
    ) {
        self.exponeaIntegrationType = exponeaIntegrationType
        self.route = route
        self.streamAuthProvider = streamAuthProvider
        self.onAuthorizationError = onAuthorizationError
    }
    
    public func getPath() throws -> String {
        let baseUrl = exponeaIntegrationType.baseUrl.last == "/" ? String(exponeaIntegrationType.baseUrl.dropLast()) : exponeaIntegrationType.baseUrl
        
        return try getRoute(baseUrl: baseUrl)
    }
}

private extension RequestFactory {
    func getRoute(baseUrl: String) throws -> String {
        switch exponeaIntegrationType.type {
        case .project(let projectToken):
            switch route {
            case .identifyCustomer:
                return baseUrl + "/track/v2/projects/\(projectToken)/customers"
            case .customEvent:
                return baseUrl + "/track/v2/projects/\(projectToken)/customers/events"
            case .customerAttributes:
                return baseUrl + "/data/v2/projects/\(projectToken)/customers/attributes"
            case .consents:
                return baseUrl + "/data/v2/projects/\(projectToken)/consent/categories"
            case .campaignClick:
                return baseUrl + "/track/v2/projects/\(projectToken)/campaigns/clicks"
            case .inAppMessages:
                return baseUrl + "/webxp/s/\(projectToken)/inappmessages?compatibility=3"
            case .pushSelfCheck:
                return baseUrl + "/campaigns/send-self-check-notification?project_id=\(projectToken)"
            case .appInbox:
                return baseUrl + "/webxp/projects/\(projectToken)/appinbox/fetch"
            case .appInboxMarkRead:
                return baseUrl + "/webxp/projects/\(projectToken)/appinbox/markasread"
            case .personalizedInAppContentBlocks:
                return baseUrl + "/webxp/s/\(projectToken)/inappcontentblocks?v=2"
            case .inAppContentBlocks:
                return baseUrl + "/wxstatic/projects/\(projectToken)/bundle-ios.json?v=2"
            case let .segmentation(cookie):
                return baseUrl + "/webxp/projects/\(projectToken)/segments?cookie=\(cookie)"
            case let .linkIds(cookie):
                return baseUrl + "/webxp/projects/\(projectToken)/cookies/\(cookie)/link-ids"
            default:
                throw ExponeaError.unknownError("Invalid ExponeaIntegrationType value for given path.")
            }
        case .stream(let streamId):
            switch route {
            case .identifyCustomer:
                return baseUrl + "/track/u/v1/customers?stream_id=\(streamId)"
            case .customEvent:
                return baseUrl + "/track/u/v1/customers/events?stream_id=\(streamId)"
            case .recommendations:
                return baseUrl + "/optimization/streams/\(streamId)/recommend/user"
            case .consents:
                return baseUrl + "/data/v2/streams/\(streamId)/consent/categories"
            case .campaignClick:
                return baseUrl + "/track/u/v1/campaigns/clicks?stream_id=\(streamId)"
            case .inAppMessages:
                return baseUrl + "/webxp/streams/\(streamId)/inappmessages?compatibility=3"
            case .pushSelfCheck:
                return baseUrl + "/campaigns/streams/\(streamId)/send-self-check-notification"
            case .appInbox:
                return baseUrl + "/webxp/streams/\(streamId)/appinbox/fetch"
            case .appInboxMarkRead:
                return baseUrl + "/webxp/streams/\(streamId)/appinbox/markasread"
            case .personalizedInAppContentBlocks:
                return baseUrl + "/webxp/streams/\(streamId)/inappcontentblocks?v=2"
            case .inAppContentBlocks:
                return baseUrl + "/wxstatic/streams/\(streamId)/bundle-ios.json?v=2"
            case let .segmentation(cookie):
                return baseUrl + "/webxp/streams/\(streamId)/segments?cookie=\(cookie)"
            case .linkIds(cookie: let cookie):
                return baseUrl + "/webxp/streams/\(streamId)/cookies/\(cookie)/link-ids"
            default:
                throw ExponeaError.unknownError("Invalid ExponeaIntegrationType value for given path.")
            }
        }
    }

    /// Returns true if this route should have Stream JWT added to the request.
    /// JWT is only added for Stream-scoped endpoints: Tracking v3, Stream WebXP, App Inbox, and related.
    func shouldAddJwtToRequest() -> Bool {
        switch route {
        case .customerAttributes:
            return false // Project-only route; no JWT in Stream (route not used for Stream)
        default:
            return true
        }
    }
}

public extension RequestFactory {
    func prepareRequest(
        parameters: RequestParametersType? = nil,
        customerIds: [String: String]? = nil
    ) throws -> URLRequest {
        let path = try getPath()
        
        guard let url = URL(sharedSafeString: path) else {
            throw ExponeaError.unknownError("The URL cannot be nil.")
        }
        var request = URLRequest(url: url)

        // Create the basic request
        request.httpMethod = route.method.rawValue
        request.addValue(
            Constants.Repository.contentType,
            forHTTPHeaderField: Constants.Repository.headerContentType
        )
        request.addValue(
            Constants.Repository.contentType,
            forHTTPHeaderField: Constants.Repository.headerAccept
        )

        // Authorization by integration type
        switch exponeaIntegrationType.type {
        case .project:
            if let project = exponeaIntegrationType as? ExponeaProject {
                switch project.authorization {
                case .none: break
                case let .token(token):
                    request.addValue("Token \(token)", forHTTPHeaderField: Constants.Repository.headerAuthorization)
                case let .bearer(token):
                    request.addValue("Bearer \(token)", forHTTPHeaderField: Constants.Repository.headerAuthorization)
                }
            }
        case .stream:
            if shouldAddJwtToRequest(),
               let jwtHeader = streamAuthProvider?.getAuthorizationHeader?(),
               !jwtHeader.isEmpty {
                request.addValue(jwtHeader, forHTTPHeaderField: Constants.Repository.headerAuthorization)
            }
        }

        // Add parameters as request body in JSON format, if we have any
        if let parameters = parameters?.requestParameters {
            var params = parameters

            // Add customer ids if separate
            if let customerIds = customerIds {
                params["customer_ids"] = customerIds
            }

            do {
                request.httpBody = try JSONSerialization.data(
                    withJSONObject: params.removeNill().removeInfinity(),
                    options: []
                )
            } catch {
                Exponea.logger.log(
                    .error,
                    message: "Failed to serialise request body into JSON: \(error.localizedDescription)"
                )
                Exponea.logger.log(.verbose, message: "Request parameters: \(params)")
            }
        }

        // Log request if necessary
        if Exponea.logger.logLevel == .verbose {
            Exponea.logger.log(.verbose, message: "Created request: \n\(request.describe)")
        }

        return request
    }

    typealias CompletionHandler = ((Data?, URLResponse?, Error?) -> Void)

    /// Delay in seconds before retrying after 401/403 to allow JWT refresh.
    private static let jwtRetryDelay: TimeInterval = 1.0
    
    func handler<T: ErrorInitialisable>(with completion: @escaping ((EmptyResult<T>) -> Void)) -> CompletionHandler {
        return { (data, response, error) in
            self.process(response, data: data, error: error, resultAction: { (result) in
                switch result {
                case .success:
                    DispatchQueue.main.async {
                        completion(.success)
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        let error = T.create(from: error)
                        completion(.failure(error))
                    }
                }
            })
        }
    }

    func handler<T: Decodable>(with completion: @escaping ((Result<T>) -> Void)) -> CompletionHandler {
        return { (data, response, error) in
            self.process(response, data: data, error: error, resultAction: { (result) in
                switch result {
                case .success(let data):
                    do {
                        let jsonDecoder = JSONDecoder()
                        jsonDecoder.dateDecodingStrategy = .secondsSince1970
                        let object = try jsonDecoder.decode(T.self, from: data)
                        DispatchQueue.main.async {
                            completion(.success(object))
                        }
                    } catch {
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            })
        }
    }

    /// Returns a completion handler and a closure to run the request. Retries once on 401 or 403 when no token was sent (2 attempts total).
    /// - Parameter executeRequest: Closure that performs the request. It receives a setter; call it with `true` if the request includes a JWT, `false` otherwise, before starting the request.
    /// - Returns: (completionHandler, startRequest). Call startRequest() after assigning executeRequest to run the first request.
    func handlerWithRetry(
        executeRequest: @escaping (@escaping (Bool) -> Void) -> Void,
        completion: @escaping (Result<Data>) -> Void
    ) -> (CompletionHandler, () -> Void) {
        let hasRetried = Ref(false)
        let requestHadJwtRef = Ref(false)
        let decoder = JSONDecoder()
        let runRequest: () -> Void = { executeRequest({ requestHadJwtRef.value = $0 }) }
        let completionHandler: CompletionHandler = { [self] (data, response, error) in
            self.process(
                response,
                data: data,
                error: error,
                requestHadJwt: requestHadJwtRef.value,
                resultAction: { result in
                    DispatchQueue.main.async {
                        completion(result)
                    }
                },
                onRetryableAuthFailure: { statusCode, responseData in
                    if !hasRetried.value {
                        hasRetried.value = true
                        Exponea.logger.log(.verbose, message: "JWT: Retrying request after \(statusCode)")
                        DispatchQueue.main.asyncAfter(deadline: .now() + RequestFactory.jwtRetryDelay) {
                            runRequest()
                        }
                    } else {
                        let errorResponse = responseData.flatMap { try? decoder.decode(ErrorResponse.self, from: $0) }
                        DispatchQueue.main.async {
                            completion(.failure(RepositoryError.notAuthorized(errorResponse)))
                        }
                    }
                }
            )
        }
        return (completionHandler, runRequest)
    }

    func handler<T: ErrorInitialisable>(
        withRetry executeRequest: @escaping (@escaping (Bool) -> Void) -> Void,
        completion: @escaping (EmptyResult<T>) -> Void
    ) -> (CompletionHandler, () -> Void) {
        let (h, start) = handlerWithRetry(executeRequest: executeRequest) { result in
            switch result {
            case .success:
                completion(.success)
            case .failure(let error):
                completion(.failure(T.create(from: error)))
            }
        }
        return (h, start)
    }

    func handler<T: Decodable>(
        withRetry executeRequest: @escaping (@escaping (Bool) -> Void) -> Void,
        completion: @escaping (Result<T>) -> Void
    ) -> (CompletionHandler, () -> Void) {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .secondsSince1970
        let (h, start) = handlerWithRetry(executeRequest: executeRequest) { result in
            let mapped: Result<T>
            switch result {
            case .success(let data):
                do {
                    mapped = .success(try jsonDecoder.decode(T.self, from: data))
                } catch {
                    mapped = .failure(error)
                }
            case .failure(let error):
                mapped = .failure(error)
            }
            DispatchQueue.main.async { completion(mapped) }
        }
        return (h, start)
    }

    func mockHandler<T: Decodable>(response: Data, model: T.Type, with completion: @escaping ((Result<T>) -> Void)) {
        do {
            let jsonDecoder = JSONDecoder()
            jsonDecoder.dateDecodingStrategy = .secondsSince1970
            let object = try jsonDecoder.decode(T.self, from: response)
            completion(.success(object))
        } catch {
            completion(.failure(error))
        }
    }

    func process(
        _ response: URLResponse?,
        data: Data?,
        error: Error?,
        requestHadJwt: Bool = false,
        resultAction: @escaping ((Result<Data>) -> Void),
        onRetryableAuthFailure: ((Int, Data?) -> Void)? = nil
    ) {
        // Check if we have any response at all
        guard let response = response else {
            DispatchQueue.main.async {
                resultAction(.failure(RepositoryError.connectionError))
            }
            return
        }

        // Log response if needed
        if Exponea.logger.logLevel == .verbose {
            Exponea.logger.log(.verbose, message: """
                Response received:
                \(response.description(with: data, error: error))
                """)
        }

        // Make sure we got the correct response type
        guard let httpResponse = response as? HTTPURLResponse else {
            DispatchQueue.main.async {
                resultAction(.failure(RepositoryError.invalidResponse(response)))
            }
            return
        }

        if let error = error {
            // handle server errors
            switch httpResponse.statusCode {
            case 500..<600:
                resultAction(.failure(RepositoryError.serverError(nil)))
            default:
                resultAction(.failure(error))
            }
        } else if let data = data {
            let decoder = JSONDecoder()

            // Switch on status code
            switch httpResponse.statusCode {
            case 401:
                let errorResponse = try? decoder.decode(ErrorResponse.self, from: data)
                let endpoint = (try? self.getPath()) ?? ""
                self.onAuthorizationError?(endpoint, 401, data)
                if case .stream = exponeaIntegrationType.type,
                   shouldAddJwtToRequest(), let onRetry = onRetryableAuthFailure {
                    onRetry(401, data)
                    return
                }
                resultAction(.failure(RepositoryError.notAuthorized(errorResponse)))

            case 403:
                let endpoint = (try? self.getPath()) ?? ""
                if case .stream = exponeaIntegrationType.type,
                   !requestHadJwt, shouldAddJwtToRequest(), let onRetry = onRetryableAuthFailure {
                    self.onAuthorizationError?(endpoint, 403, data)
                    onRetry(403, data)
                    return
                }
                let text = String(data: data, encoding: .utf8)
                resultAction(.failure(RepositoryError.missingData(text ?? httpResponse.description)))

            case 410:
                let text = String(data: data, encoding: .utf8)
                resultAction(.failure(RepositoryError.resourceGone(text)))

            case 400, 404, 405..<410, 411..<500:
                if httpResponse.statusCode == 404 {
                    let errorResponse = try? decoder.decode(MultipleErrorResponse.self, from: data)
                    resultAction(.failure(RepositoryError.urlNotFound(errorResponse)))
                } else {
                    let text = String(data: data, encoding: .utf8)
                    resultAction(.failure(RepositoryError.missingData(text ?? httpResponse.description)))
                }

            case 500...Int.max:
                if case .recommendations = route {
                    let errorMessage = String(data: data, encoding: .utf8) ?? ""
                    resultAction(.failure(RepositoryError.missingData(errorMessage)))
                } else {
                    let errorResponse = try? decoder.decode(MultipleErrorResponse.self, from: data)
                    resultAction(.failure(RepositoryError.serverError(errorResponse)))
                }
            default:
                // We assume all other status code are a success
                resultAction(.success(data))
            }
        } else {
            resultAction(.failure(RepositoryError.invalidResponse(response)))
        }
    }
}
