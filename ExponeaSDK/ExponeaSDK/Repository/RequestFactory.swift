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
    var baseURL: String
    var projectToken: String
    var route: Routes

    init(baseURL: String, projectToken: String, route: Routes) {
        self.baseURL = baseURL
        self.projectToken = projectToken
        self.route = route
    }

    var path: String {
        switch self.route {
        case .trackCustomers: return baseURL + "/track/v2/projects/\(projectToken)/customers"
        case .trackEvents: return baseURL + "/track/v2/projects/\(projectToken)/customers/events"
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

    var method: HTTPMethod { return .post }
}

extension RequestFactory {
    func prepareRequest(authorization: String?,
                        trackingParam: TrackingParameters? = nil,
                        customersParam: CustomerParameters? = nil) -> NSMutableURLRequest {
        let request = NSMutableURLRequest()

        // Create the basic request
        request.url = URL(string: path)!
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
        case .trackCustomers, .trackEvents:
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
}
