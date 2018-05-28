//
//  Customer+DataType.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 12/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import CoreData

extension Customer {
    var ids: [String: String] {
        var ids: [String: String] = ["cookie": uuid!.uuidString]
        
        // Add customer identification.
        if let registeredId = registeredId {
            ids["registered"] = registeredId
        }
        
        return ids
    }
}
