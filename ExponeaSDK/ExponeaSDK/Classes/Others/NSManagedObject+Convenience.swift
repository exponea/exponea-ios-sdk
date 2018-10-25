//
//  NSManagedObject+Convenience.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 25/10/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import CoreData

public extension NSManagedObject {
    convenience init(context: NSManagedObjectContext) {
        let name = String(describing: type(of: self))
        let entity = NSEntityDescription.entity(forEntityName: name, in: context)!
        self.init(entity: entity, insertInto: context)
    }
}
