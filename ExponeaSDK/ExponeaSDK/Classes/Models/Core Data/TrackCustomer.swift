//
//  TrackCustomer+CoreDataClass.swift
//  
//
//  Created by Dominik Hadl on 02/07/2018.
//
//

import Foundation
import CoreData

public class TrackCustomer: NSManagedObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TrackCustomer> {
        return NSFetchRequest<TrackCustomer>(entityName: "TrackCustomer")
    }
    
    @NSManaged public var projectToken: String?
    @NSManaged public var timestamp: Double
    @NSManaged public var customer: Customer?
    @NSManaged public var properties: NSSet?
    
    var dataTypes: [DataType] {
        var data: [DataType] = []
        
        // Add project token.
        if let token = projectToken {
            data.append(.projectToken(token))
        }
        
        // Convert all properties to key value items.
        if let properties = properties as? Set<KeyValueItem> {
            var props: [String: JSONValue] = [:]
            properties.forEach({
                DatabaseManager.processProperty(key: $0.key,
                                                value: $0.value,
                                                into: &props)
            })
            data.append(.properties(props))
        }
        
        return data
    }
}

// MARK: - Core Data -

extension TrackCustomer {
    @objc(addPropertiesObject:)
    @NSManaged public func addToProperties(_ value: KeyValueItem)
    
    @objc(removePropertiesObject:)
    @NSManaged public func removeFromProperties(_ value: KeyValueItem)
    
    @objc(addProperties:)
    @NSManaged public func addToProperties(_ values: NSSet)
    
    @objc(removeProperties:)
    @NSManaged public func removeFromProperties(_ values: NSSet)
}
