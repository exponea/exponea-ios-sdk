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
/// - unknownError(String?)
public enum ExponeaError: Error {
    case notConfigured
    case configurationError(String)
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
            
        case .unknownError(let details):
            return "Unknown error. \(details != nil ? details! : "")"
        }
    }
}
