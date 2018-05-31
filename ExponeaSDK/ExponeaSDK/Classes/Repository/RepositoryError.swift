//
//  RepositoryError.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 10/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// Data types that thrown the possible errors from the repository manager.
///
/// - missingData: Holds any missing data while trying to call the Expone API.
/// - invalidResponse: Holds any invalid response when calling the Exponea API.
public enum RepositoryError: LocalizedError {
    case missingData(String)
    case serverError(ErrorResponse?)
    case urlNotFound(ErrorResponse?)
    case invalidResponse(URLResponse?)
    
    /// Return a formatted error message while doing API calls to Exponea.
    public var errorDescription: String? {
        switch self {
        case .missingData(let details):
            return "Request is missing required data: \(details)"
        case .invalidResponse(let response):
            return "An invalid response was received from the API: \(response != nil ? "\(response!)" : "No response")"
        case .serverError(let response):
            return response?.errors.description ?? "There was a server error, please try again later."
        case .urlNotFound(let response):
            return response?.errors.description ?? "Requested URL was not found."
        }
    }
}
