//
//  KeyValueItem+CoreDataClass.swift
//
//
//  Created by Dominik Hadl on 02/07/2018.
//
//

import Foundation
import CoreData

protocol HasKeyValueProperties: class {
    var properties: NSSet? { get }

    func addToProperties(_ value: KeyValueItem)
    func removeFromProperties(_ value: KeyValueItem)
    func addToProperties(_ values: NSSet)
    func removeFromProperties(_ values: NSSet)
}

@objc(KeyValueItem)
class KeyValueItem: NSManagedObjectWithContext {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<KeyValueItem> {
        return NSFetchRequest<KeyValueItem>(entityName: "KeyValueItem")
    }

    @NSManaged public var key: String?
    @NSManaged public var value: NSObject?
    @NSManaged public var customer: Customer?

}
