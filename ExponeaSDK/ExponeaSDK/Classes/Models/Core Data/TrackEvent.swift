//
//  TrackEvent+CoreDataClass.swift
//  
//
//  Created by Dominik Hadl on 02/07/2018.
//
//

import Foundation
import CoreData

@objc(TrackEvent)
public class TrackEvent: NSManagedObject {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TrackEvent> {
        return NSFetchRequest<TrackEvent>(entityName: "TrackEvent")
    }
    
    @NSManaged public var eventType: String?
    @NSManaged public var projectToken: String?
    @NSManaged public var timestamp: Double
    @NSManaged public var customer: Customer?
    @NSManaged public var properties: NSSet?
    
}

extension TrackEvent {
    
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
                guard let key = $0.key, let object = $0.value else {
                    Exponea.logger.log(.warning, message: """
                        Skipping KeyValueItem with empty key (\($0.key ?? "N/A"))) \
                        or value (\(String(describing: $0.value))).
                        """)
                    return
                }
                
                props[key] = DatabaseManager.processObject(object)
            })
            data.append(.properties(props))
        }
        
        // Add event type.
        if let eventType = eventType {
            data.append(.eventType(eventType))
        }
        
        // Add timestamp if we have it, otherwise none.
        data.append(.timestamp(timestamp == 0 ? nil : timestamp))
        
        return data
    }
}

// MARK: - Core Data -

extension TrackEvent: HasKeyValueProperties {
    @objc(addPropertiesObject:)
    @NSManaged public func addToProperties(_ value: KeyValueItem)
    
    @objc(removePropertiesObject:)
    @NSManaged public func removeFromProperties(_ value: KeyValueItem)
    
    @objc(addProperties:)
    @NSManaged public func addToProperties(_ values: NSSet)
    
    @objc(removeProperties:)
    @NSManaged public func removeFromProperties(_ values: NSSet)
}
