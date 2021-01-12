//
//  DataType+Codable.swift
//  ExponeaSDKShared
//
//  Created by Panaxeo on 07/09/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

extension DataType: Codable {
    enum CodingKeys: CodingKey {
        case customerIds
        case properties
        case timestamp
        case eventType
        case pushNotificationToken
    }

    private struct PushNotificationToken: Codable {
        var token: String?
        var authorized: Bool
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var result: DataType?
        if let value = try? container.decode([String: String].self, forKey: .customerIds) {
            result = .customerIds(value)
        }
        if let value = try? container.decode([String: JSONValue].self, forKey: .properties) {
            result = .properties(value)
        }
        if case .some = try? container.decodeNil(forKey: .timestamp) {
            result = .timestamp(nil)
        }
        if let value = try? container.decode(Double.self, forKey: .timestamp) {
            result = .timestamp(value)
        }
        if let value = try? container.decode(String.self, forKey: .eventType) {
            result = .eventType(value)
        }
        if let value = try? container.decode(PushNotificationToken.self, forKey: .pushNotificationToken) {
            result = .pushNotificationToken(token: value.token, authorized: value.authorized)
        }
        guard let initialized = result else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Unknown case of DataType",
                    underlyingError: nil
                )
            )
        }
        self = initialized
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .customerIds(let value):
            try container.encode(value, forKey: .customerIds)
        case .properties(let value):
            try container.encode(value, forKey: .properties)
        case .timestamp(let value):
            try container.encode(value, forKey: .timestamp)
        case .eventType(let value):
            try container.encode(value, forKey: .eventType)
        case .pushNotificationToken(let token, let authorized):
            try container.encode(
                PushNotificationToken(token: token, authorized: authorized),
                forKey: .pushNotificationToken
            )
        }
    }
}
