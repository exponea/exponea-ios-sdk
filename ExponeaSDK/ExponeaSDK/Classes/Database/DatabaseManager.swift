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
    
    internal let persistentContainer: NSPersistentContainer

    /// Managed Context for Core Data
    private var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    internal init(persistentStoreDescriptions: [NSPersistentStoreDescription]? = nil) throws {
        let bundle = Bundle(for: DatabaseManager.self)
        let container = NSPersistentContainer(name: "DatabaseModel", bundle: bundle)!
        var loadError: Error?
        
        // Set descriptions if needed
        if let descriptions = persistentStoreDescriptions {
            container.persistentStoreDescriptions = descriptions
        }

        container.loadPersistentStores(completionHandler: { loadError = $1 })
        
        // Throw an error if we failed at loading a persistent store
        if let error = loadError {
            Exponea.logger.log(.error, message: "Unresolved error \(error.localizedDescription).")
            throw DatabaseManagerError.unableToLoadPeristentStore(error.localizedDescription)
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Set the container
        persistentContainer = container
        
        // Initialise customer
        _ = customer
        Exponea.logger.log(.verbose, message: "Database initialised with customer:\n\(customer)")
    }
}

extension DatabaseManager {
    public var customer: CustomerThreadSafe {
        return context.performAndWait {
            return CustomerThreadSafe(customerManagedObject)
        }
    }

    private var customerManagedObject: Customer {
        return context.performAndWait {
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
                try context.save()
                Exponea.logger.log(.verbose, message: "New customer created with UUID: \(customer.uuid!)")
            } catch let saveError as NSError {
                let error = DatabaseManagerError.saveCustomerFailed(saveError.localizedDescription)
                Exponea.logger.log(.error, message: error.localizedDescription)
            } catch {
                Exponea.logger.log(.error, message: error.localizedDescription)
            }
            
            return customer
        }
    }
    
    private func fetchCustomerAndUpdate(with ids: [String: JSONValue]) -> Customer {
        return context.performAndWait {
            let customer = self.customerManagedObject
            
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
                // We don't know if anything changed
                if context.hasChanges {
                    try context.save()
                }
            } catch {
                let error = DatabaseManagerError.saveCustomerFailed(error.localizedDescription)
                Exponea.logger.log(.error, message: error.localizedDescription)
            }
            
            return customer
        }
    }
    
    private func fetchCustomerAndUpdate(pushToken: String?) -> Customer {
        return context.performAndWait {
            let customer = self.customerManagedObject
            
            // Update push token and last token track date
            customer.pushToken = pushToken
            customer.lastTokenTrackDate = .init()
            
            do {
                // We don't know if anything changed
                if context.hasChanges {
                    try context.save()
                }
            } catch {
                let error = DatabaseManagerError.saveCustomerFailed(error.localizedDescription)
                Exponea.logger.log(.error, message: error.localizedDescription)
            }
            
            return customer
        }
    }
}

extension DatabaseManager: DatabaseManagerType {
    public func updateEvent(withId id: NSManagedObjectID, withData data: DataType) throws {
        try context.performAndWait {
            guard let object = try? context.existingObject(with: id) else {
                throw DatabaseManagerError.objectDoesNotExist
            }
            guard object is TrackEvent else {
                throw DatabaseManagerError.wrongObjectType
            }
            let event = object as! TrackEvent
            switch data {
            case .projectToken(let token):
                event.projectToken = token
            case .eventType(let eventType):
                event.eventType = eventType
            case .timestamp(let time):
                event.timestamp = time ?? event.timestamp
            case .properties(let properties):
                processProperties(properties, into: event)
            default:
                return
            }
            Exponea.logger.log(.verbose, message: "going to modify event with id \(event.objectID)")
            try context.save()
        }
    }

    /// Add any type of event into coredata.
    ///
    /// - Parameter data: See `DataType` for more information. Types specified below are required at minimum.
    ///     - `projectToken`
    ///     - `customerId`
    ///     - `properties`
    ///     - `timestamp`
    ///     - `eventType`
    public func trackEvent(with data: [DataType]) throws {
        try context.performAndWait {
            let trackEvent = TrackEvent(context: context)
            trackEvent.customer = customerManagedObject
            
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

            Exponea.logger.log(.verbose, message: "Adding track event \(trackEvent.eventType ?? "nil") to database: \(trackEvent.objectID)")
            
            // Insert the object into the database
            context.insert(trackEvent)
            
            // Save the customer properties into CoreData
            try context.save()
        }
    }
    
    /// Add customer properties into the database.
    ///
    /// - Parameter data: See `DataType` for more information. Types specified below are required at minimum.
    ///     - `projectToken`
    ///     - `customerId`
    ///     - `properties`
    ///     - `timestamp`
    /// - Throws: <#throws value description#>
    public func identifyCustomer(with data: [DataType]) throws {
        try context.performAndWait {
            let trackCustomer = TrackCustomer(context: context)
            trackCustomer.customer = customerManagedObject
            
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
                    item.value = (token ?? "") as NSString
                    trackCustomer.addToProperties(item)

                    // Update push token on customer
                    trackCustomer.customer = fetchCustomerAndUpdate(pushToken: token)
                    
                default:
                    break
                }
            }
            
            // Save the customer properties into CoreData
            try context.save()
        }
    }
    
    /// <#Description#>
    ///
    /// - Parameters:
    ///   - properties: <#properties description#>
    ///   - object: <#object description#>
    internal func processProperties(_ properties: [String: JSONValue],
                                    into object: HasKeyValueProperties) {
        for property in properties {
            let existingProperties = object.properties as? Set<KeyValueItem>
            let existingProperty: KeyValueItem? = existingProperties?.first(where: { $0.key == property.key })
            if existingProperty != nil {
                existingProperty!.value = property.value.objectValue
            } else {
                let item = KeyValueItem(context: context)
                item.key = property.key
                item.value = property.value.objectValue
                object.addToProperties(item)
            }
        }
    }
    
    /// Fetch all Tracking Customers from CoreData
    ///
    /// - Returns: An array of tracking customer updates, if any are stored in the database.
    public func fetchTrackCustomer() throws -> [TrackCustomerThreadSafe] {
        return try context.performAndWait {
            let trackCustomerEvents: [TrackCustomer] = try context.fetch(TrackCustomer.fetchRequest())
            return trackCustomerEvents.map {TrackCustomerThreadSafe($0)}
        }
    }
    
    /// Fetch all Tracking Events from CoreData
    ///
    /// - Returns: An array of tracking events, if any are stored in the database.
    public func fetchTrackEvent() throws -> [TrackEventThreadSafe] {
        return try context.performAndWait {
            let trackEvents: [TrackEvent] = try context.fetch(TrackEvent.fetchRequest())
            return trackEvents.map {TrackEventThreadSafe($0)}
        }
    }

    /// Increase number of retries on TrackCustomer object
    public func addRetry(_ customerEvent: TrackCustomerThreadSafe) throws {
        try context.performAndWait {
            guard let object = try? context.existingObject(with: customerEvent.managedObjectID) else {
                throw DatabaseManagerError.objectDoesNotExist
            }
            guard let trackCustomer: TrackCustomer = object as? TrackCustomer else {
                throw DatabaseManagerError.objectDoesNotExist
            }
            let retries = NSNumber(integerLiteral: customerEvent.retries + 1)
            trackCustomer.retries = retries
            try context.save()
        }
    }

    /// Increase number of retries on TrackEventThreadSafe object
    public func addRetry(_ event: TrackEventThreadSafe) throws {
        try context.performAndWait {
            guard let object = try? context.existingObject(with: event.managedObjectID) else {
                throw DatabaseManagerError.objectDoesNotExist
            }
            guard let trackEvent: TrackEvent = object as? TrackEvent else {
                throw DatabaseManagerError.objectDoesNotExist
            }
            let retries = NSNumber(integerLiteral: event.retries + 1)
            trackEvent.retries = retries
            try context.save()
        }
    }
    
    /// Detele a Tracking Event Object from CoreData
    ///
    /// - Parameters:
    ///     - object: Tracking Event Object to be deleted from CoreData
    public func delete(_ trackEvent: TrackEventThreadSafe) throws {
        try context.performAndWait {
            guard let object = try? context.existingObject(with: trackEvent.managedObjectID) else {
                return
            }
            context.delete(object)
            try context.save()
        }
    }
    
    /// Detele a Tracking Customer Object from CoreData
    ///
    /// - Parameters:
    ///     - object: Tracking Customer Object to be deleted from CoreData
    public func delete(_ trackCustomer: TrackCustomerThreadSafe) throws {
        try context.performAndWait {
            guard let object = try? context.existingObject(with: trackCustomer.managedObjectID) else {
                return
            }
            context.delete(object)
            try context.save()
        }
    }

    
    public func clear() throws {
        // Delete all persistent stores
        let coordinator = persistentContainer.persistentStoreCoordinator
        for store in coordinator.persistentStores {
            // Make sure we have URL and it is a NSSQLiteStoreType
            guard let url = store.url, store.type == NSSQLiteStoreType else { continue }
            try coordinator.destroyPersistentStore(at: url, ofType: NSSQLiteStoreType, options: nil)
        }

        // Load new persistent store
        var loadError: Error?
        persistentContainer.loadPersistentStores(completionHandler: { loadError = $1 })
        
        // Throw an error if we failed at loading a persistent store
        if let loadError = loadError {
            let error = DatabaseManagerError.unableToLoadPeristentStore(loadError.localizedDescription)
            Exponea.logger.log(.error, message: error.localizedDescription)
            throw error
        }
    }
}
