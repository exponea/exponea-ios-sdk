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

    internal lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "DatabaseModel")
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error {
                Exponea.logger.log(.error, message: "Unresolved error \(error.localizedDescription).")
            }
        })
        return container
    }()

    init() {
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    }

    /// Managed Context for Core Data
    var managedObjectContext: NSManagedObjectContext {
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
    func saveContext() -> Bool {
        let context = managedObjectContext
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
        managedObjectContext.delete(object)
        return saveContext()
    }

}

extension DatabaseManager: DatabaseManagerType {

    /// Add any type of event into coredata.
    ///
    /// - Parameters:
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - properties: Properties that should be updated
    ///     - timestamp: Timestamp should always be UNIX timestamp format
    ///     - eventType: Type of event to be tracked
    public func trackEvent(with data: [DataType]) -> Bool {
        let trackEvents = TrackEvents(context: managedObjectContext)
        let trackEventsProperties = TrackEventsProperties(context: managedObjectContext)

        for type in data {
            switch type {
            case .projectToken(let token):
                trackEvents.projectToken = token

            case .customerId(let id):
                trackEvents.customerIdKey = id.key
                trackEvents.customerIdValue = id.value as? NSObject

            case .eventType(let event):
                trackEvents.eventType = event

            case .timestamp(let time):
                trackEvents.timestamp = time ?? Date().timeIntervalSince1970

            case .properties(let properties):
                // Add the event properties to the events entity
                for property in properties {
                    trackEventsProperties.key = property.key
                    trackEventsProperties.value = property.value as? NSObject
                    trackEvents.addToTrackEventsProperties(trackEventsProperties)
                }
            }
        }

        // Save the customer properties into CoreData
        return saveContext()
    }

    /// Add customer properties into coredata.
    ///
    /// - Parameters:
    ///     - projectToken: Project token (you can find it in the overview section of your Exponea project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - properties: Properties that should be updated
    ///     - timestamp: Timestamp should always be UNIX timestamp format
    public func trackCustomer(with data: [DataType]) -> Bool {
        let trackCustomers = TrackCustomers(context: managedObjectContext)
        let trackCustomerProperties = TrackCustomersProperties(context: managedObjectContext)

        for type in data {
            switch type {
            case .projectToken(let token):
                trackCustomers.projectToken = token

            case .customerId(let id):
                trackCustomers.customerIdKey = id.key
                trackCustomers.customerIdValue = id.value as? NSObject

            case .timestamp(let time):
                trackCustomers.timestamp = time ?? Date().timeIntervalSince1970

            case .properties(let properties):
                // Add the customer properties to the customer entity
                for property in properties {
                    trackCustomerProperties.key = property.key
                    trackCustomerProperties.value = property.value as? NSObject
                    trackCustomers.addToTrackCustomerProperties(trackCustomerProperties)
                }
            default:
                break
            }
        }

        // Save the customer properties into CoreData
        return saveContext()
    }

    /// Fetch all Tracking Customers from CoreData
    public func fetchTrackCustomer() -> [TrackCustomers] {

        var trackCustomers = [TrackCustomers]()

        do {
            let context = managedObjectContext
            trackCustomers = try context.fetch(TrackCustomers.fetchRequest())
        } catch {
            Exponea.logger.log(.error, message: "Unresolved error \(error.localizedDescription)")
        }

        return trackCustomers
    }

    /// Fetch all Tracking Events from CoreData
    public func fetchTrackEvents() -> [TrackEvents] {

        var trackEvents = [TrackEvents]()

        do {
            let context = managedObjectContext
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
