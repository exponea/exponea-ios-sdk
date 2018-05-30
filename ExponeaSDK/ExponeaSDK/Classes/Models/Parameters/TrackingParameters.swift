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
    var customerIds: [AnyHashable: JSONConvertible]
    /// Object with customer properties.
    var properties: [AnyHashable: JSONConvertible]
    /// Timestamp should always be UNIX timestamp format
    var timestamp: Double?
    /// Name of the tracking event.
    var eventType: String?

    init(customerIds: [AnyHashable: JSONConvertible],
         properties: [AnyHashable: JSONConvertible],
         timestamp: Double? = nil,
         eventType: String? = nil) {
        self.customerIds = customerIds
        self.properties = properties
        self.timestamp = timestamp
        self.eventType = eventType
    }
}

extension TrackingParameters: RequestParametersType {
    var parameters: [AnyHashable: JSONConvertible] {
        var parameters: [AnyHashable: JSONConvertible] = [:]

        /// Preparing customers_ids params
        parameters["customer_ids"] = customerIds
        
        /// Preparing properties param
        parameters["properties"] = properties

        /// Preparing timestamp param
        if let timestamp = timestamp {
            parameters["timestamp"] = timestamp
        }
        /// Preparing eventType param
        if let eventType = eventType {
            parameters["event_type"] = eventType
        }

        return parameters
    }
}
