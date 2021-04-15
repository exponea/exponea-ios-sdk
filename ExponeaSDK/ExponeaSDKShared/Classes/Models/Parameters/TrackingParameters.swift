//
//  TrackingParameters.swift
//  ExponeaSDKShared
//
//  Created by Dominik Hádl on 24/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// A Group of parameters used to track any kind of event.
/// Depending on what king of tracking, you can use a combination of properties.
public struct TrackingParameters {
    /// Customer identification.
    var customerIds: [String: String]
    /// Object with customer properties.
    var properties: [String: JSONValue]
    /// Timestamp should always be UNIX timestamp format
    var timestamp: Double?
    /// Name of the tracking event.
    var eventType: String?

    public init(
        customerIds: [String: String],
        properties: [String: JSONValue],
        timestamp: Double? = nil,
        eventType: String? = nil
    ) {
        self.customerIds = customerIds
        self.properties = properties
        self.timestamp = timestamp
        self.eventType = eventType
    }
}

extension TrackingParameters: RequestParametersType {
    public var parameters: [String: JSONValue] {
        var parameters: [String: JSONValue] = [:]

        /// Preparing customers_ids params
        parameters["customer_ids"] = .dictionary(customerIds.mapValues { $0.jsonValue })

        if eventType != Constants.EventTypes.pushDelivered && eventType != Constants.EventTypes.pushOpen {
            parameters["age"] =
                .double(Double(Date().timeIntervalSince1970) - (timestamp ?? Double(Date().timeIntervalSince1970)))
        } else {
            /// Preparing timestamp param
            if let timestamp = timestamp {
                parameters["timestamp"] = .double(timestamp)
            }
        }
        if eventType == Constants.EventTypes.campaignClick {
            parameters["url"] = properties["url"]
            parameters["properties"] = properties["properties"]
        } else {
            /// Preparing properties param
            parameters["properties"] = .dictionary(properties)
        }

        /// Preparing eventType param
        if let eventType = eventType {
            parameters["event_type"] = .string(eventType)
        }

        return parameters
    }
}
