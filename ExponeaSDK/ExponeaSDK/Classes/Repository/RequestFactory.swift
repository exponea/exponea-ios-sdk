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
        case .customerRecommendation: return baseUrl + "/data/v2/projects/\(projectToken)/customers/attributes"
        case .customerAttributes: return baseUrl + "/data/v2/\(projectToken)/customers/attributes"
        case .customerEvents: return baseUrl + "/data/v2/projects/\(projectToken)/customers/events"
        case .banners: return baseUrl + "/data/v2/projects/\(projectToken)/configuration/banners"
        case .personalization:
            return baseUrl + "/data/v2/projects/\(projectToken)/customers/personalisation/show-banners"
        }
    }
    
    public var method: HTTPMethod { return .post }
}

extension RequestFactory {
    func prepareRequest(authorization: Authorization,
                        parameters: RequestParametersType? = nil,
                        customerIds: [String: JSONValue]? = nil) -> URLRequest {
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
        case .basic(let secret):
            request.addValue("Basic \(secret)",
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
    
    func handler(with completion: @escaping ((EmptyResult) -> Void)) -> CompletionHandler {
        return { (data, response, error) in
            self.process(response, data: data, error: error, resultAction: { (result) in
                switch result {
                case .success(_):
                    DispatchQueue.main.async {
                        completion(.success)
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
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
                        let object = try JSONDecoder().decode(T.self, from: data)
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
        if let response = response, Exponea.logger.logLevel == .verbose {
            Exponea.logger.log(.verbose, message: """
                Response received:
                \(response.description(with: data, error: error))
                """)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            DispatchQueue.main.async {
                resultAction(.failure(RepositoryError.invalidResponse(response)))
            }
            return
        }
        
        if let error = error {
            resultAction(.failure(error))
        } else if let data = data {
            let decoder = JSONDecoder()
            
            // Switch on status code
            switch httpResponse.statusCode {
            case 400, 405..<500:
                let text = String(data: data, encoding: .utf8)
                resultAction(.failure(RepositoryError.missingData(text ?? response?.description ?? "N/A")))
                
            case 404:
                let errorResponse = try? decoder.decode(ErrorResponse.self, from: data)
                resultAction(.failure(RepositoryError.urlNotFound(errorResponse)))
                
            case 500...Int.max:
                let errorResponse = try? decoder.decode(ErrorResponse.self, from: data)
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
