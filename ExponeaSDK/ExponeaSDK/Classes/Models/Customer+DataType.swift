//
//  Customer+DataType.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 12/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import CoreData

// API Expected structure
//
// customer_ids[0] = [cookie = "aaa", "registered" : "something", "emial" : "some"]

public typealias CustomerIds = (uuid: KeyValueItem, registeredId: KeyValueItem?)

extension Customer {
    var ids: CustomerIds {
        var registeredItem: KeyValueItem?
        
        if let id = registeredId {
            registeredItem = KeyValueItem(key: "registered", value: id)
        }
        
        return (KeyValueItem(key: "cookie", value: uuid!.uuidString), registeredItem)
    }
    
    var asDataType: DataType {
        return .customerId(ids)
    }
}
