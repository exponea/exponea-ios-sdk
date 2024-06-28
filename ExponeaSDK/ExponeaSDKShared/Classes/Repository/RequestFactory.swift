//
//  RequestFactory.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 09/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// Path route with projectId
public struct RequestFactory {
    let exponeaProject: ExponeaProject
    let route: Routes

    public init(exponeaProject: ExponeaProject, route: Routes) {
        self.exponeaProject = exponeaProject
        self.route = route
    }

    public var path: String {
        let baseUrl = exponeaProject.baseUrl.last == "/" ?
        String(exponeaProject.baseUrl.dropLast()) : exponeaProject.baseUrl
        let projectToken = exponeaProject.projectToken
        switch self.route {
        case .identifyCustomer: return baseUrl + "/track/v2/projects/\(projectToken)/customers"
        case .customEvent: return baseUrl + "/track/v2/projects/\(projectToken)/customers/events"
        case .customerAttributes: return baseUrl + "/data/v2/projects/\(projectToken)/customers/attributes"
        case .consents: return baseUrl + "/data/v2/projects/\(projectToken)/consent/categories"
        case .campaignClick:
            return baseUrl + "/track/v2/projects/\(projectToken)/campaigns/clicks"
        case .inAppMessages:
            return baseUrl + "/webxp/s/\(projectToken)/inappmessages?v=1"
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
        }
    }
}

public extension RequestFactory {
    func prepareRequest(
        parameters: RequestParametersType? = nil,
        customerIds: [String: String]? = nil
    ) -> URLRequest {
        var request = URLRequest(url: URL(sharedSafeString: path)!)

        // Create the basic request
        request.httpMethod = route.method.rawValue
        request.addValue(Constants.Repository.contentType,
                         forHTTPHeaderField: Constants.Repository.headerContentType)
        request.addValue(Constants.Repository.contentType,
                         forHTTPHeaderField: Constants.Repository.headerAccept)

        // Add authorization if it was provided
        switch exponeaProject.authorization {
        case .none: break
        case let .token(token):
            request.addValue("Token \(token)",
                forHTTPHeaderField: Constants.Repository.headerAuthorization)
        case let .bearer(token):
            request.addValue("Bearer \(token)",
                forHTTPHeaderField: Constants.Repository.headerAuthorization)
        }

        // Add parameters as request body in JSON format, if we have any
        if let parameters = parameters?.requestParameters {
            var params = parameters

            // Add customer ids if separate
            if let customerIds = customerIds {
                params["customer_ids"] = customerIds
            }

            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: params.removeNill(), options: [])
            } catch {
                Exponea.logger.log(.error,
                                   message: "Failed to serialise request body into JSON: \(error.localizedDescription)")
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

    func process(_ response: URLResponse?, data: Data?, error: Error?,
                 resultAction: @escaping ((Result<Data>) -> Void)) {
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
            case 400, 405..<500:
                let text = String(data: data, encoding: .utf8)
                resultAction(.failure(RepositoryError.missingData(text ?? httpResponse.description)))

            case 401:
                let response = try? decoder.decode(ErrorResponse.self, from: data)
                resultAction(.failure(RepositoryError.notAuthorized(response)))

            case 404:
                let errorResponse = try? decoder.decode(MultipleErrorResponse.self, from: data)
                resultAction(.failure(RepositoryError.urlNotFound(errorResponse)))

            case 500...Int.max:
                let errorResponse = try? decoder.decode(MultipleErrorResponse.self, from: data)
                resultAction(.failure(RepositoryError.serverError(errorResponse)))

            default:
                // We assume all other status code are a success
                resultAction(.success(data))
            }
        } else {
            resultAction(.failure(RepositoryError.invalidResponse(response)))
        }
    }
}
