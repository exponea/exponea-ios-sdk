//
//  RequestFactory.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 09/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// Path route with projectId
struct RequestFactory {
    public var baseUrl: String
    public var projectToken: String
    public var route: Routes

    public init(baseUrl: String, projectToken: String, route: Routes) {
        self.baseUrl = baseUrl
        self.projectToken = projectToken
        self.route = route
    }

    public var path: String {
        switch self.route {
        case .identifyCustomer: return baseUrl + "/track/v2/projects/\(projectToken)/customers"
        case .customEvent: return baseUrl + "/track/v2/projects/\(projectToken)/customers/events"
        case .customerAttributes: return baseUrl + "/data/v2/projects/\(projectToken)/customers/attributes"
        case .banners: return baseUrl + "/data/v2/projects/\(projectToken)/configuration/banners"
        case .consents: return baseUrl + "/data/v2/projects/\(projectToken)/consent/categories"
        case .personalization:
            return baseUrl + "/data/v2/projects/\(projectToken)/customers/personalisation/show-banners"
        case .campaignClick:
            return baseUrl + "/track/v2/projects/\(projectToken)/campaigns/clicks"
        case .inAppMessages:
            return baseUrl + "/webxp/s/\(projectToken)/inappmessages"
        }
    }
}

extension RequestFactory {
    func prepareRequest(authorization: Authorization,
                        parameters: RequestParametersType? = nil,
                        customerIds: [String: JSONValue]? = nil) -> URLRequest {
        var request = URLRequest(url: URL(string: path)!)

        // Create the basic request
        request.httpMethod = route.method.rawValue
        request.addValue(Constants.Repository.contentType,
                         forHTTPHeaderField: Constants.Repository.headerContentType)
        request.addValue(Constants.Repository.contentType,
                         forHTTPHeaderField: Constants.Repository.headerAccept)

        // Add authorization if it was provided
        switch authorization {
        case .none: break
        case .token(let token):
            request.addValue("Token \(token)",
                forHTTPHeaderField: Constants.Repository.headerAuthorization)
        }

        // Add parameters as request body in JSON format, if we have any
        if let parameters = parameters?.requestParameters {
            var params = parameters

            // Add customer ids if separate
            if let customerIds = customerIds {
                params["customer_ids"] = customerIds.mapValues({ $0.jsonConvertible })
            }

            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
            } catch {
                Exponea.logger.log(.error,
                                   message: "Failed to serialise request body into JSON: \(error.localizedDescription)")
                Exponea.logger.log(.verbose, message: "Request parameters: \(params)")
            }
        }

        // Log request if necessary
        if Exponea.logger.logLevel == .verbose {
            Exponea.logger.log(.verbose, message: "Created request: \n\(request.description)")
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
            //handle server errors
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
