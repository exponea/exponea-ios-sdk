//
//  Authorization.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 10/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// Data type to identify which kind of authorization the sdk should use
/// when making http calls for the Exponea API.
public enum Authorization {
    case none
    case token(String)
    case basic(String)
}

extension Authorization: CustomStringConvertible {
    public var description: String {
        switch self {
        case .none:
            return "No Authorization"
        case .token(_):
            return "Token Authorization (token redacted)"
        case .basic(_):
            return "Basic Authorization (token redacted)"
        }
    }
}

extension Authorization: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .none:
            return "No Authorization"
        case .token(let token):
            return "Token Authorization (\(token))"
        case .basic(let token):
            return "Basic Authorization (\(token))"
        }
    }
}
