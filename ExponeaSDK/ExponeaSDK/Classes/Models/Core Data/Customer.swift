//
//  Customer+CoreDataClass.swift
//  
//
//  Created by Dominik Hadl on 02/07/2018.
//
//

import Foundation
import CoreData

@objc(Customer)
public class Customer: NSManagedObject {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Customer> {
        return NSFetchRequest<Customer>(entityName: "Customer")
    }
    
    @NSManaged public var uuid: UUID?
    @NSManaged public var pushToken: String?
    @NSManaged public var lastTokenTrackDate: Date?
    @NSManaged public var customIds: NSSet?
    @NSManaged public var trackCustomer: NSSet?
    @NSManaged public var trackEvent: NSSet?
    
    var ids: [String: JSONValue] {
        let ids: [String: JSONValue]? = managedObjectContext?.performAndWait {
            var data: [String: JSONValue] = ["cookie": .string(uuid!.uuidString)]
            
            // Convert all properties to key value items.
            if let properties = customIds as? Set<KeyValueItem> {
                properties.forEach({
                    guard let key = $0.key, let object = $0.value else {
                        Exponea.logger.log(.warning, message: """
                            Skipping KeyValueItem with empty key (\($0.key ?? "N/A"))) \
                            or value (\(String(describing: $0.value))).
                            """)
                        return
                    }
                    
                    data[key] = DatabaseManager.processObject(object)
                })
            }
            return data
        }
        return ids ?? [:]
    }
}

// MARK: - CustomStringConvertible -

extension Customer {
    public override var description: String {
        var text = "[Customer]\n"
        
        // Add cookie, push token and last track date
        text += "UUID (cookie): \(uuid != nil ? uuid!.uuidString : "N/A")\n"
        text += "Push Token: \(pushToken ?? "N/A")"
        text += "Last Push Token Track Date: \(lastTokenTrackDate ?? Date.distantPast)"
        
        if let ids = customIds as? Set<KeyValueItem>, ids.count > 0 {
            text += "Custom IDs: "
            for id in ids {
                text += "\"\(id.key!)\" = \(id.value!), "
            }
        }

        text += "\n"
        
        return text
    }
}

// MARK: - Core Data -

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
