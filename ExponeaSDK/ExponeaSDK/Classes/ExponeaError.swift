//
//  ExponeaError.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 10/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// Data types that thrown the possible errors on the configuration object.
///
/// - notConfigured
/// - configurationError(String)
/// - authorizationInsufficient(String)
/// - unknownError(String?)
public enum ExponeaError: Error {
    case notConfigured
    case configurationError(String)
    case authorizationInsufficient(String)
    case unknownError(String?)

    public var localizedDescription: String {
        switch self {
        case .notConfigured:
            return """
            Exponea SDK is not configured properly. Please, double check your Exponea setup.
            """

        case .configurationError(let details):
            return """
            The provided configuration contains error(s). Please, fix them before initialising Exponea SDK.
            \(details)
            """

        case .authorizationInsufficient(let required):
            return """
            You don't have sufficient authorizaiton to perform this action. Please, double check your
            authorization status. This function requires authorization \(required.capitalized).
            """

        case .unknownError(let details):
            return "Unknown error. \(details ?? "")"
        }
    }
}
