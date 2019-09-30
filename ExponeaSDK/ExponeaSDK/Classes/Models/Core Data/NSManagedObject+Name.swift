//
//  NSManagedObject+Name.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 30/06/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import CoreData

extension NSManagedObject {
    var name: String {
        get {
            return String(describing: self)
        }
    }
}
