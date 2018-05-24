//
//  TrackingParameters.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 24/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

struct TrackingParameters {
    var customerIds: [String: JSONConvertible]
    var properties: [String: JSONConvertible]
    var timestamp: Double?
    var eventType: String?

    init(customerIds: [String: JSONConvertible], properties: [String: JSONConvertible],
         timestamp: Double? = nil, eventType: String? = nil) {
        self.customerIds = customerIds
        self.properties = properties
        self.timestamp = timestamp
        self.eventType = eventType
    }

}

extension TrackingParameters: RequestParametersType {
    var parameters: [String: JSONConvertible] {
        var parameters: [String: JSONConvertible] = [:]

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
