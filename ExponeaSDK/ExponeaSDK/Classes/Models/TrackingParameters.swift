//
//  TrackingParameters.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 24/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

struct TrackingParameters {
    var customer: CustomerIds
    var properties: [KeyValueItem]
    var timestamp: Double?
    var eventType: String?

    init(customer: CustomerIds, properties: [KeyValueItem],
         timestamp: Double? = nil, eventType: String? = nil) {
        self.customer = customer
        self.properties = properties
        self.timestamp = timestamp
        self.eventType = eventType
    }

}

extension TrackingParameters {
    var parameters: [String: Any]? {
        var preparedParam: [String: Any] = [:]

        /// Preparing customers_ids params
        var customerParameters: [String: Any] = [customer.uuid.key: customer.uuid.value]
        if let id = customer.registeredId {
            customerParameters[id.key] = id.value
        }
        
        preparedParam["customer_ids"] = customerParameters

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
