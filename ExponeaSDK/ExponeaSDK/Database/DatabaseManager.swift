//
//  DatabaseManager.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 03/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import CoreData

/// The Entities Manager class is responsible for persist the data using CoreData Framework.
/// Persisted data will be used to interact with the Exponea API.
public class DatabaseManager {

    public lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "DatabaseModel")
        container.loadPersistentStores(completionHandler: { (_, error) in //(storeDescription, error) in
            if let error = error {
                Exponea.logger.log(.error, message: "Unresolved error \(error.localizedDescription).")
            }
        })
        return container
    }()

    /// Managed Context for Core Data
    func managedObjectContext() -> NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    /// Save all changes in CoreData
    func saveContext(object: NSManagedObject) {
        do {
            try object.managedObjectContext?.save()
        } catch {
            // TODO: Logging
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }

    /// Save all changes in CoreData
    func saveContext() -> Bool {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
                return true
            } catch {
                Exponea.logger.log(.error, message: "Unresolved error \(error.localizedDescription)")
            }
        }
        return false
    }

    /// Delete a specific object in CoreData
    fileprivate func deleteObject(_ object: NSManagedObject) -> Bool {
        managedObjectContext().delete(object)
        return saveContext()
    }

}

extension DatabaseManager: DatabaseManagerType {

    /// Update the Customer properties and persists it into the CoreData in the TrackCustomer Entity.
    ///
    /// - Parameters:
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - properties: Properties that should be updated
    public func trackCustomer(projectToken: String, customerId: KeyValueModel, properties: [KeyValueModel]) -> Bool {

        let trackCustomer = TrackCustomers(context: persistentContainer.viewContext)
        let trackCustomerProperties = TrackCustomersProperties(context: persistentContainer.viewContext)

        trackCustomer.projectToken = projectToken
        trackCustomer.customerIdKey = customerId.key
        trackCustomer.customerIdValue = customerId.value as? NSObject
        trackCustomer.timestamp = NSDate().timeIntervalSince1970

        // Add the customer properties to the property entity
        for property in properties {
            trackCustomerProperties.key = property.key
            trackCustomerProperties.value = property.value as? NSObject

            trackCustomer.addToTrackCustomerProperties(trackCustomerProperties)
        }

        // Save the customer properties into CoreData
        return saveContext()
    }

    /// Add events into a customer
    ///
    /// - Parameters:
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - properties: Properties that should be updated
    ///     - timestamp: Timestamp should always be UNIX timestamp format
    ///     - eventType: Type of event to be tracked
    public func trackEvents(projectToken: String, customerId: KeyValueModel, properties: [KeyValueModel],
                            timestamp: Double?, eventType: String?) -> Bool {
        let trackEvents = TrackEvents(context: persistentContainer.viewContext)
        let trackEventsProperties = TrackEventsProperties(context: persistentContainer.viewContext)

        trackEvents.projectToken = projectToken
        trackEvents.customerIdKey = customerId.key
        trackEvents.customerIdValue = customerId.value as? NSObject

        if let timestamp = timestamp {
            trackEvents.timestamp = timestamp
        }
        if let eventType = eventType {
            trackEvents.eventType = eventType
        }

        // Add the event properties to the events entity
        for property in properties {
            trackEventsProperties.key = property.key
            trackEventsProperties.value = property.value as? NSObject
            trackEvents.addToTrackEventsProperties(trackEventsProperties)
        }

        // Save the customer properties into CoreData
        return saveContext()
    }

    /// Track the device information when the user install the APP for the first time. This event
    /// is fired only once for the whole APP lifetime.
    ///
    /// - Parameters:
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - properties: Properties that should be updated
    ///     - eventType: Type of event to be tracked
    public func trackInstall(projectToken: String, properties: [KeyValueModel]) -> Bool {
        let trackEvents = TrackEvents(context: persistentContainer.viewContext)
        let trackEventsProperties = TrackEventsProperties(context: persistentContainer.viewContext)

        trackEvents.projectToken = projectToken
        trackEvents.eventType = Constants.EventTypes.installation

        // Add the event properties to the events entity
        for property in properties {
            trackEventsProperties.key = property.key
            trackEventsProperties.value = property.value as? NSObject
            trackEvents.addToTrackEventsProperties(trackEventsProperties)
        }

        // Save the customer properties into CoreData
        return saveContext()
    }

    /// Fetch all Tracking Customers from CoreData
    public func fetchTrackCustomer() -> [TrackCustomers]? {

        var trackCustomers = [TrackCustomers]()

        do {
            let context = persistentContainer.viewContext
            trackCustomers = try context.fetch(TrackCustomers.fetchRequest())
        } catch {
            Exponea.logger.log(.error, message: "Unresolved error \(error.localizedDescription)")
        }

        return trackCustomers
    }

    /// Fetch all Tracking Events from CoreData
    public func fetchTrackEvents() -> [TrackEvents]? {

        var trackEvents = [TrackEvents]()

        do {
            let context = persistentContainer.viewContext
            trackEvents = try context.fetch(TrackEvents.fetchRequest())
        } catch {
            Exponea.logger.log(.error, message: "Unresolved error \(error.localizedDescription)")
        }

        return trackEvents
    }

    /// Detele a Tracking Customer Object from CoreData
    ///
    /// - Parameters:
    ///     - object: Tracking Customer Object to be deleted from CoreData
    public func deleteTrackCustomer(object: AnyObject) -> Bool {
        guard let trackObject = object as? TrackCustomers else {
            Exponea.logger.log(.error, message: "Invalid object to delete.")
            return false
        }
        return deleteObject(trackObject)
    }

    /// Detele a Tracking Event Object from CoreData
    ///
    /// - Parameters:
    ///     - object: Tracking Event Object to be deleted from CoreData
    public func deleteTrackEvent(object: AnyObject) -> Bool {
        guard let trackEvent = object as? TrackEvents else {
            Exponea.logger.log(.error, message: "Invalid object to delete.")
            return false
        }

        return deleteObject(trackEvent)
    }
}
