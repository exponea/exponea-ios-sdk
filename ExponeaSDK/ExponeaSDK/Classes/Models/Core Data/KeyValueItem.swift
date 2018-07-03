//
//  KeyValueItem+CoreDataClass.swift
//  
//
//  Created by Dominik Hadl on 02/07/2018.
//
//

import Foundation
import CoreData

public class KeyValueItem: NSManagedObject {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<KeyValueItem> {
        return NSFetchRequest<KeyValueItem>(entityName: "KeyValueItem")
    }
    
    @NSManaged public var key: String?
    @NSManaged public var value: NSObject?
    @NSManaged public var customer: Customer?
    
}
