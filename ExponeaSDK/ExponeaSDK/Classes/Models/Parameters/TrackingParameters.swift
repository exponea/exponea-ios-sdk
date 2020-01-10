//
//  TrackingParameters.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 24/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// A Group of parameters used to track any kind of event.
/// Depending on what king of tracking, you can use a combination of properties.
struct TrackingParameters {
    /// Customer identification.
    var customerIds: [String: JSONValue]
    /// Object with customer properties.
    var properties: [String: JSONValue]
    /// Timestamp should always be UNIX timestamp format
    var timestamp: Double?
    /// Name of the tracking event.
    var eventType: String?

    init(customerIds: [String: JSONValue],
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
    var parameters: [String: JSONValue] {
        var parameters: [String: JSONValue] = [:]

        /// Preparing customers_ids params
        parameters["customer_ids"] = .dictionary(customerIds)

        if eventType == Constants.EventTypes.campaignClick {
            parameters["url"] = properties["url"]
            parameters["properties"] = properties["properties"]
            parameters["age"] =
                .double(Double(Date().timeIntervalSince1970) - (timestamp ?? Double(Date().timeIntervalSince1970)))
        } else {
            /// Preparing properties param
            parameters["properties"] = .dictionary(properties)
        }

        /// Preparing timestamp param
        if let timestamp = timestamp {
            parameters["timestamp"] = .double(timestamp)
        }
        /// Preparing eventType param
        if let eventType = eventType {
            parameters["event_type"] = .string(eventType)
        }

        return parameters
    }
}
