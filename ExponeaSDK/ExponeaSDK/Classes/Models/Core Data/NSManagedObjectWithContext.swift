//
//  NSManagedObjectWithContext.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 15/10/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation
import CoreData

class NSManagedObjectWithContext: NSManagedObject {
    // https://stackoverflow.com/a/39239651/3179004 we need to expose superclass initializer for fetching
    @objc
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

    init(context: NSManagedObjectContext) {
        let name = String(describing: type(of: self))
        let entity = NSEntityDescription.entity(forEntityName: name, in: context)!
        super.init(entity: entity, insertInto: context)
    }
}
