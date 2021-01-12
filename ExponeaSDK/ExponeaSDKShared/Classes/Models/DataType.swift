//
//  DataType.swift
//  ExponeaSDKShared
//
//  Created by Dominik Hádl on 18/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// Data types that can be associated with tracked events (described in `EventType`).
///
/// - customerId
/// - properties
/// - timestamp
/// - eventType
public enum DataType: Equatable {
    /// Identifier of your customer, can be anything from an email to UUIDs.
    case customerIds([String: String])

    /// Custom properties that you would like to add to the tracking event,
    /// these can include any relevant information for you.
    case properties([String: JSONValue])

    /// Timestamp of the tracked event in UNIX epoch time, if value is `nil` current date is used.
    case timestamp(Double?)

    /// For some tracked events you can also provide an event type
    case eventType(String)

    /// Token and authorization status for that token
    /// If nil, it will delete the existing push notification token if any.
    case pushNotificationToken(token: String?, authorized: Bool)
}

extension Array where Iterator.Element == DataType {
    public var eventTypes: [String] {
        return compactMap { if case .eventType(let eventType) = $0 { return eventType } else { return nil } }
    }

    public var latestTimestamp: Double? {
        return compactMap {
            if case .timestamp(let timestamp) = $0 { return timestamp } else { return nil }
        }.sorted().last
    }

    public var properties: [String: JSONConvertible?] {
        var properties: [String: JSONConvertible?] = [:]
        forEach {
            if case .properties(let props) = $0 {
                props.forEach { properties.updateValue($0.value.jsonConvertible, forKey: $0.key) }
            }
        }
        return properties
    }

    public func addProperties(_ properties: [String: JSONConvertible]?) -> [DataType] {
        guard let jsonProperties = properties?.mapValues({ $0.jsonValue }) else {
            return self
        }
        var hasProperties = false
        var updatedData = self.map { (dataType: DataType) -> DataType in
            if case .properties(let props) = dataType {
                hasProperties = true
                return .properties(jsonProperties.merging(props, uniquingKeysWith: { (_, new) in new }))
            } else {
                return dataType
            }
        }
        if !hasProperties {
            updatedData.append(.properties(jsonProperties))
        }
        return updatedData
    }
}
