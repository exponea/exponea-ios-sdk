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
        case .trackCustomer: return baseURL + "/track/v2/projects/\(projectToken)/customers"
        case .trackEvent: return baseURL + "/track/v2/projects/\(projectToken)/customers/events"
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
    func prepareRequest(authorization: String?,
                        trackingParam: TrackingParameters? = nil,
                        customersParam: CustomerParameters? = nil) -> URLRequest {
        var request = URLRequest(url: URL(string: path)!)

        // Create the basic request
        request.httpMethod = method.rawValue
        request.addValue(Constants.Repository.contentType,
                         forHTTPHeaderField: Constants.Repository.headerContentType)
        request.addValue(Constants.Repository.contentType,
                         forHTTPHeaderField: Constants.Repository.headerAccept)

        // Add authorization if it was provided
        if let authorization = authorization {
            request.addValue(authorization,
                             forHTTPHeaderField: Constants.Repository.headerAuthorization)
        }

        var parameters: [String: Any]?

        // Assign parameters if necessary
        switch route {
        case .trackCustomer, .trackEvent:
            parameters = trackingParam?.parameters
        case .tokenRotate, .tokenRevoke:
            parameters = nil
        default:
            parameters = customersParam?.parameters
        }

        // Add parameters as request body in JSON format, if we have any.
        if let parameters = parameters {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
            } catch {
                Exponea.logger.log(.error, message: "Failed to serialise request body into JSON.")
                Exponea.logger.log(.verbose, message: "Request body: \(parameters)")
            }
        }

        return request
    }
    
    typealias CompletionHandler = ((Data?, URLResponse?, Error?) -> Void)
    
    func handler(with completion: @escaping ((EmptyResult) -> Void)) -> CompletionHandler {
        return { (_, _, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success)
            }
        }
    }
    
    func handler<T: Decodable>(with completion: @escaping ((Result<T>) -> Void)) -> CompletionHandler {
        return { (data, response, error) in
            if let error = error {
                completion(.failure(error))
            } else if let data = data {
                let decoder = JSONDecoder()
                do {
                    let object = try decoder.decode(T.self, from: data)
                    completion(.success(object))
                } catch {
                    completion(.failure(error))
                }
            } else {
                // FIXME: Fix this
                let error = NSError(domain: "", code: 0, userInfo: nil)
                completion(.failure(error))
            }
        }
    }
}
