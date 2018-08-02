//
//  DatabaseManager.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 03/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import CoreData

/// The Database Manager class is responsible for persist the data using CoreData Framework.
/// Persisted data will be used to interact with the Exponea API.
public class DatabaseManager {

    internal lazy var persistentContainer: NSPersistentContainer = {
        let bundle = Bundle(for: DatabaseManager.self)
        let container = NSPersistentContainer(name: "DatabaseModel", bundle: bundle)!
        
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error {
                Exponea.logger.log(.error, message: "Unresolved error \(error.localizedDescription).")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return container
    }()

    init() {
        #if DISABLE_PERSISTENCE
        Exponea.logger.log(.warning, message: "Disable persistence flag is active, clearing database contents.")
        
        let coordinator = persistentContainer.persistentStoreCoordinator
        guard let url = persistentContainer.persistentStoreDescriptions.first?.url else {
            Exponea.logger.log(.error, message: "Can't get url of persistent store, clearing failed.")
            return
        }
    
        do {
            try coordinator.destroyPersistentStore(at: url, ofType: NSSQLiteStoreType, options: nil)
            Exponea.logger.log(.verbose, message: "Database contents cleared.")
            
            persistentContainer.loadPersistentStores(completionHandler: { _, error in
                if let error = error {
                    Exponea.logger.log(.error, message: "Failed to create new database: \(error.localizedDescription).")
                }
            })
            
        } catch {
            Exponea.logger.log(.error, message: "Error clearing database: \(error.localizedDescription)")
        }
        #endif
        
        // Initialise customer
        _ = customer
        Exponea.logger.log(.verbose, message: "Database initialised with customer:\n\(customer)")
    }

    /// Managed Context for Core Data
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    /// Save all changes in CoreData
    func saveContext(object: NSManagedObject) {
        do {
            try object.managedObjectContext?.save()
        } catch {
            Exponea.logger.log(.error, message: "Unresolved error \(error.localizedDescription)")
        }
    }

    /// Save all changes in CoreData
    func saveContext() throws {
        if context.hasChanges {
            try context.save()
        }
    }

    /// Delete a specific object in CoreData
    fileprivate func deleteObject(_ object: NSManagedObject) throws {
        context.delete(object)
        try saveContext()
    }
}

extension DatabaseManager {
    public var customer: Customer {
        do {
            let customers: [Customer] = try context.fetch(Customer.fetchRequest())
            
            // If we have customer return it, otherwise create a new one
            if let customer = customers.first {
                return customer
            }
        } catch {
            Exponea.logger.log(.warning, message: "No customer found saved in database, will create. \(error)")
        }
        
        // Create and insert the object
        let customer = Customer(context: context)
        customer.uuid = UUID()
        context.insert(customer)
        
        do {
            try saveContext()
            Exponea.logger.log(.verbose, message: "New customer created with UUID: \(customer.uuid!)")
        } catch let saveError as NSError {
            let error = DatabaseManagerError.saveCustomerFailed(saveError.localizedDescription)
            Exponea.logger.log(.error, message: error.localizedDescription)
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
        }
        
        return customer
    }
    
    func fetchCustomerAndUpdate(with ids: [String: JSONValue]) -> Customer {
        let customer = self.customer
        
        // Add the ids to the customer entity
        for id in ids {
            // Check if we have existing
            if let item = customer.customIds?.first(where: { (existing) -> Bool in
                guard let existing = existing as? KeyValueItem else { return false }
                return existing.key == id.key
            }) as? KeyValueItem {
                // Update value, since it has changed
                item.value = id.value.objectValue
                Exponea.logger.log(.verbose, message: """
                    Updating value of existing customerId (\(id.key)) with value: \(id.value.jsonConvertible).
                    """)
            } else {
                // Create item and insert it
                let item = KeyValueItem(context: context)
                item.key = id.key
                item.value = id.value.objectValue
                context.insert(item)
                customer.addToCustomIds(item)
                
                Exponea.logger.log(.verbose, message: """
                    Creating new customerId (\(id.key)) with value: \(id.value.jsonConvertible).
                    """)
            }
        }
        
        do {
            try saveContext()
        } catch {
            let error = DatabaseManagerError.saveCustomerFailed(error.localizedDescription)
            Exponea.logger.log(.error, message: error.localizedDescription)
        }
        
        return customer
    }
}

extension DatabaseManager: DatabaseManagerType {

    /// Add any type of event into coredata.
    ///
    /// - Parameter data: See `DataType` for more information. Types specified below are required at minimum.
    ///     - `projectToken`
    ///     - `customerId`
    ///     - `properties`
    ///     - `timestamp`
    ///     - `eventType`
    public func trackEvent(with data: [DataType]) throws {
        let trackEvent = TrackEvent(context: context)
        trackEvent.customer = customer
        
        // Always specify a timestamp
        trackEvent.timestamp = Date().timeIntervalSince1970

        for type in data {
            switch type {
            case .projectToken(let token):
                trackEvent.projectToken = token
                
            case .eventType(let event):
                trackEvent.eventType = event

            case .timestamp(let time):
                trackEvent.timestamp = time ?? trackEvent.timestamp

            case .properties(let properties):
                // Add the event properties to the events entity
                processProperties(properties, into: trackEvent)
                
            default:
                break
            }
        }
        
        Exponea.logger.log(.verbose, message: "Adding track event to database: \(trackEvent.objectID)")

        // Insert the object into the database
        context.insert(trackEvent)
        
        // Save the customer properties into CoreData
        try saveContext()
    }
    
    /// Add customer properties into the database.
    ///
    /// - Parameter data: See `DataType` for more information. Types specified below are required at minimum.
    ///     - `projectToken`
    ///     - `customerId`
    ///     - `properties`
    ///     - `timestamp`
    /// - Throws: <#throws value description#>
    public func trackCustomer(with data: [DataType]) throws {
        let trackCustomer = TrackCustomer(context: context)
        trackCustomer.customer = customer
        
        // Always specify a timestamp
        trackCustomer.timestamp = Date().timeIntervalSince1970

        for type in data {
            switch type {
            case .projectToken(let token):
                trackCustomer.projectToken = token

            case .customerIds(let ids):
                trackCustomer.customer = fetchCustomerAndUpdate(with: ids)

            case .timestamp(let time):
                trackCustomer.timestamp = time ?? trackCustomer.timestamp

            case .properties(let properties):
                // Add the customer properties to the customer entity
                processProperties(properties, into: trackCustomer)
                
            case .pushNotificationToken(let token):
                let item = KeyValueItem(context: context)
                item.key = "apple_push_notification_id"
                item.value = token as NSString
                trackCustomer.addToProperties(item)
                
            default:
                break
            }
        }

        // Save the customer properties into CoreData
        try saveContext()
    }

    /// <#Description#>
    ///
    /// - Parameters:
    ///   - properties: <#properties description#>
    ///   - object: <#object description#>
    internal func processProperties(_ properties: [String: JSONValue],
                                    into object: HasKeyValueProperties) {
        for property in properties {
            let item = KeyValueItem(context: context)
            item.key = property.key
            item.value = property.value.objectValue
            context.insert(item)
            object.addToProperties(item)
        }
    }
    
    /// Fetch all Tracking Customers from CoreData
    ///
    /// - Returns: An array of tracking customer updates, if any are stored in the database.
    public func fetchTrackCustomer() throws -> [TrackCustomer] {
        return try context.fetch(TrackCustomer.fetchRequest())
    }
    
    /// Fetch all Tracking Events from CoreData
    ///
    /// - Returns: An array of tracking events, if any are stored in the database.
    public func fetchTrackEvent() throws -> [TrackEvent] {
        return try context.fetch(TrackEvent.fetchRequest())
    }

    /// Detele a Tracking Event Object from CoreData
    ///
    /// - Parameters:
    ///     - object: Tracking Event Object to be deleted from CoreData
    public func delete(_ object: TrackEvent) throws {
        try deleteObject(object)
    }

    /// Detele a Tracking Customer Object from CoreData
    ///
    /// - Parameters:
    ///     - object: Tracking Customer Object to be deleted from CoreData
    public func delete(_ object: TrackCustomer) throws {
        try deleteObject(object)
    }
}
