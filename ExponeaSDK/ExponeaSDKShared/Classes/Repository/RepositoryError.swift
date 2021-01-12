//
//  RepositoryError.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 10/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

public protocol ErrorInitialisable: Error {
    static func create(from error: Error) -> Self
}

/// Data types that thrown the possible errors from the repository manager.
///
/// - missingData: Holds any missing data while trying to call the Expone API.
/// - invalidResponse: Holds any invalid response when calling the Exponea API.
public enum RepositoryError: LocalizedError, ErrorInitialisable {
    case notAuthorized(ErrorResponse?)
    case missingData(String)
    case serverError(MultipleErrorResponse?)
    case urlNotFound(MultipleErrorResponse?)
    case invalidResponse(URLResponse?)
    case connectionError
    case unknown(Error)

    /// Return a formatted error message while doing API calls to Exponea.
    public var errorDescription: String? {
        switch self {
        case .notAuthorized(let response):
            let message = response?.error ?? "No details provided."
            return "Missing or invalid authorization: \(message)"
        case .missingData(let details):
            return "Request is missing required data: \(details)"
        case .invalidResponse(let response):
            return "An invalid response was received from the API: " +
                "\(response != nil ? "\(String(describing: response))" : "No response")"
        case .serverError(let response):
            return response?.errors.description ?? "There was a server error, please try again later."
        case .urlNotFound(let response):
            return response?.errors.description ?? "Requested URL was not found."
        case .connectionError:
            return "No response received from the server, please check your internet connection."
        case .unknown(let error):
            return "\(error.localizedDescription)"
        }
    }

    public static func create(from error: Error) -> RepositoryError {
        if let error = error as? RepositoryError {
            return error
        } else {
            return .unknown(error)
        }
    }
}
