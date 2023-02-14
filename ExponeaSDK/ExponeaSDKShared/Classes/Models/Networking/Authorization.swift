//
//  Authorization.swift
//  ExponeaSDKShared
//
//  Created by Dominik Hadl on 10/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// Data type to identify which kind of authorization the sdk should use
/// when making http calls for the Exponea API.
public enum Authorization: Equatable, Codable {
    case none
    case token(String)
    case bearer(token: String)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(from: try? container.decode(String.self))
    }

    public init(from string: String?) {
        self = .none
        guard let string = string else {
            return
        }
        let components = string.split(separator: " ")

        if components.count == 2 {
            switch components.first {
            case "Token": self = .token(String(components[1]))
            case "Bearer": self = .bearer(token: String(components[1]))
            default: break
            }
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let encoded = encode() {
            try container.encode(encoded)
        } else {
            try container.encodeNil()
        }
    }

    public func encode() -> String? {
        switch self {
        case .none: return nil
        case let .token(token): return "Token \(token)"
        case let .bearer(token): return "Bearer \(token)"
        }
    }
}

extension Authorization: CustomStringConvertible {
    public var description: String {
        switch self {
        case .none:
            return "No Authorization"
        case .token:
            return "Token Authorization (token redacted)"
        case .bearer:
            return "Bearer Authorization (token redacted)"
        }
    }
}

extension Authorization: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .none:
            return "No Authorization"
        case let .token(token):
            return "Token Authorization (\(token))"
        case let .bearer(token):
            return "Bearer Authorization (\(token))"
        }
    }
}
