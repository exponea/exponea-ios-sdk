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
    public var baseURL: String
    public var projectToken: String
    public var route: Routes

    public init(baseURL: String, projectToken: String, route: Routes) {
        self.baseURL = baseURL
        self.projectToken = projectToken
        self.route = route
    }

    public var path: String {
        switch self.route {
        case .identifyCustomer: return baseURL + "/track/v2/projects/\(projectToken)/customers"
        case .customEvent: return baseURL + "/track/v2/projects/\(projectToken)/customers/events"
        case .trackBatch: return baseURL + "/track/v2/projects/\(projectToken)/batch"
        case .tokenRotate: return baseURL + "/data/v2/\(projectToken)/tokens/rotate"
        case .tokenRevoke: return baseURL + "/data/v2/\(projectToken)/tokens/revoke"
        case .customersProperty: return baseURL + "/data/v2/\(projectToken)/customers/property"
        case .customersId: return baseURL + "/data/v2/\(projectToken)/customers/id"
        case .customersSegmentation: return baseURL + "/data/v2/\(projectToken)/customers/segmentation"
        case .customersExpression: return baseURL + "/data/v2/\(projectToken)/customers/expression"
        case .customersPrediction: return baseURL + "/data/v2/\(projectToken)/customers/prediction"
        case .customersRecommendation: return baseURL + "/data/v2/projects/\(projectToken)/customers/attributes"
        case .customersAttributes: return baseURL + "/data/v2/\(projectToken)/customers/attributes"
        case .customersEvents: return baseURL + "/data/v2/projects/\(projectToken)/customers/events"
        case .customersAnonymize: return baseURL + "/data/v2/\(projectToken)/customers/anonymize"
        case .customersExportAllProperties: return baseURL + "/data/v2/\(projectToken)/customers/export-one"
        case .customersExportAll: return baseURL + "/data/v2/\(projectToken)/customers/export"
        }
    }

    public var method: HTTPMethod { return .post }
}

extension RequestFactory {
    func prepareRequest(authorization: Authorization,
                        parameters: RequestParametersType? = nil) -> URLRequest {
        var request = URLRequest(url: URL(string: path)!)

        // Create the basic request
        request.httpMethod = method.rawValue
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
        case .basic(let secret):
            request.addValue("Basic \(secret)",
                             forHTTPHeaderField: Constants.Repository.headerAuthorization)
        }

        // Add parameters as request body in JSON format, if we have any
        if let parameters = parameters?.requestParameters {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
            } catch {
                Exponea.logger.log(.error,
                                   message: "Failed to serialise request body into JSON: \(error.localizedDescription)")
                Exponea.logger.log(.verbose, message: "Request parameters: \(parameters)")
            }
        }

        return request
    }
    
    typealias CompletionHandler = ((Data?, URLResponse?, Error?) -> Void)
    
    func handler(with completion: @escaping ((EmptyResult) -> Void)) -> CompletionHandler {
        return { (_, _, error) in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            } else {
                DispatchQueue.main.async {
                    completion(.success)
                }
            }
        }
    }
    
    func handler<T: Decodable>(with completion: @escaping ((Result<T>) -> Void)) -> CompletionHandler {
        return { (data, response, error) in
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.failure(RepositoryError.invalidResponse(response)))
                }
                return
            }

            if let error = error {
                completion(.failure(error))
            } else if let data = data {
                let decoder = JSONDecoder()
                
                // Switch on status code
                switch httpResponse.statusCode {
                case 400..<500:
                    let errorResponse = try? decoder.decode(ErrorResponse.self, from: data)
                    DispatchQueue.main.async {
                        completion(.failure(RepositoryError.urlNotFound(errorResponse)))
                    }
                    
                case 500...Int.max:
                    let errorResponse = try? decoder.decode(ErrorResponse.self, from: data)
                    DispatchQueue.main.async {
                        completion(.failure(RepositoryError.serverError(errorResponse)))
                    }
                    
                default:
                    
                    // If all is good continue serialising
                    do {
                        let object = try decoder.decode(T.self, from: data)
                        DispatchQueue.main.async {
                            completion(.success(object))
                        }
                    } catch {
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                }
            } else {
                completion(.failure(RepositoryError.invalidResponse(response)))
            }
        }
    }
}
