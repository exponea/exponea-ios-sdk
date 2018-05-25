//
//  TrackCustomer+DataType.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 24/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

extension TrackCustomer {
    var dataTypes: [DataType] {
        var data: [DataType] = []
        
        // Add project token
        if let token = projectToken {
            data.append(.projectToken(token))
        }

        // Convert all properties to key value items
        if let properties = trackCustomerProperties as? Set<TrackCustomerProperty> {
            var props: [AnyHashable: JSONConvertible] = [:]
            properties.forEach({ props[$0.key!] = $0.value! })
            data.append(.properties(props))
        }
        
        return data
    }
}
