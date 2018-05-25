//
//  TrackEvent+DataType.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 11/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

extension TrackEvent {
    var dataTypes: [DataType] {
        var data: [DataType] = []
        
        // Add project token
        if let token = projectToken {
            data.append(.projectToken(token))
        }
        
        // Convert all properties to key value items
        if let properties = trackEventProperties as? Set<TrackEventProperty> {
            var props: [AnyHashable: JSONConvertible] = [:]
            properties.forEach({ props[$0.key!] = $0.value! })
            data.append(.properties(props))
        }
        
        // Add event type
        if let eventType = eventType {
            data.append(.eventType(eventType))
        }
        
        // Add timestamp if we have it, otherwise none
        data.append(.timestamp(timestamp == 0 ? nil : timestamp))
        
        return data
    }
}
