//
//  APIConfiguration.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 04/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// Base structure for network
struct APIConfiguration {
    /// Base address used to make the requests
    let baseURL: String
    /// HTTP Header content type
    let contentType: String

    init(baseURL: String = Constants.Repository.baseURL,
         contentType: String = Constants.Repository.contentType) {
        self.baseURL = baseURL
        self.contentType = contentType
    }
}

/// Identification of endpoints for Exponea API
enum Routes {
    case trackCustomers
    case trackEvents
    case tokenRotate
    case tokenRevoke
    case customersProperty
    case customersId
    case customersSegmentation
    case customersExpression
    case customersPrediction
    case customersRecommendation
    case customersAttributes
    case customersEvents
    case customersAnonymize
    case customersExportAllProperties
    case customersExportAll
}

/// Define the type of HTTP method used to perform the request
public enum HTTPMethod: String {
    case post = "POST"
    case put = "PUT"
    case get = "GET"
    case delete = "DELETE"
    case patch = "PATCH"
}

public enum APIResult<T> {
    case success(T)
    case failure(Error)

    var value: T? {
        if case .success(let value) = self {
            return value
        } else {
            return nil
        }
    }

    var error: Error? {
        if case .failure(let error) = self {
            return error
        } else {
            return nil
        }
    }
}
