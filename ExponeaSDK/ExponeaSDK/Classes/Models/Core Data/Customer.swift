//
//  Customer+CoreDataClass.swift
//  
//
//  Created by Dominik Hadl on 02/07/2018.
//
//

import Foundation
import CoreData

public class Customer: NSManagedObject {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Customer> {
        return NSFetchRequest<Customer>(entityName: "Customer")
    }
    
    @NSManaged public var uuid: UUID?
    @NSManaged public var customIds: NSSet?
    @NSManaged public var trackCustomer: NSSet?
    @NSManaged public var trackEvent: NSSet?
    
    var ids: [String: JSONValue] {
        var data: [String: JSONValue] = ["cookie": .string(uuid!.uuidString)]
        
        // Convert all properties to key value items.
        if let properties = customIds as? Set<KeyValueItem> {
            properties.forEach({
                DatabaseManager.processProperty(key: $0.key,
                                                value: $0.value,
                                                into: &data)
            })
        }
        
        return data
    }

}

// MARK: Generated accessors for customIds
extension Customer {
    
    @objc(addCustomIdsObject:)
    @NSManaged public func addToCustomIds(_ value: KeyValueItem)
    
    @objc(removeCustomIdsObject:)
    @NSManaged public func removeFromCustomIds(_ value: KeyValueItem)
    
    @objc(addCustomIds:)
    @NSManaged public func addToCustomIds(_ values: NSSet)
    
    @objc(removeCustomIds:)
    @NSManaged public func removeFromCustomIds(_ values: NSSet)
    
}

// MARK: Generated accessors for trackCustomer
extension Customer {
    
    @objc(addTrackCustomerObject:)
    @NSManaged public func addToTrackCustomer(_ value: TrackCustomer)
    
    @objc(removeTrackCustomerObject:)
    @NSManaged public func removeFromTrackCustomer(_ value: TrackCustomer)
    
    @objc(addTrackCustomer:)
    @NSManaged public func addToTrackCustomer(_ values: NSSet)
    
    @objc(removeTrackCustomer:)
    @NSManaged public func removeFromTrackCustomer(_ values: NSSet)
    
}

// MARK: Generated accessors for trackEvent
extension Customer {
    
    @objc(addTrackEventObject:)
    @NSManaged public func addToTrackEvent(_ value: TrackEvent)
    
    @objc(removeTrackEventObject:)
    @NSManaged public func removeFromTrackEvent(_ value: TrackEvent)
    
    @objc(addTrackEvent:)
    @NSManaged public func addToTrackEvent(_ values: NSSet)
    
    @objc(removeTrackEvent:)
    @NSManaged public func removeFromTrackEvent(_ values: NSSet)
    
}
