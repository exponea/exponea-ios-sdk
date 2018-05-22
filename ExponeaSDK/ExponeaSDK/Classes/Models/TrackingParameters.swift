//
//  TrackingParameters.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 24/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

struct TrackingParameters {
    var customerIds: [String: String]
    var properties: [KeyValueItem]
    var timestamp: Double?
    var eventType: String?

    init(customerIds: [String: String], properties: [KeyValueItem],
         timestamp: Double? = nil, eventType: String? = nil) {
        self.customerIds = customerIds
        self.properties = properties
        self.timestamp = timestamp
        self.eventType = eventType
    }

}

extension TrackingParameters {
    var parameters: [String: Any]? {
        var preparedParam: [String: Any] = [:]

        /// Preparing customers_ids params
        preparedParam["customer_ids"] = customerIds

        /// Preparing properties param
        let propertiesParam = properties.flatMap({[$0.key: $0.value]})
        preparedParam["properties"] = propertiesParam

        /// Preparing timestamp param
        if let timestamp = timestamp {
            preparedParam["timestamp"] = timestamp
        }
        /// Preparing eventType param
        if let eventType = eventType {
            preparedParam["event_type"] = eventType
        }

        return preparedParam
    }
}
