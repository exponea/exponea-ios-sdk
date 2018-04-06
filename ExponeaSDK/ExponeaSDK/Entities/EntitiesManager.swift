//
//  EntitiesManager.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 03/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import CoreData

/// Protocol to manage Tracking events
public protocol EntitieTrack: class {
    func trackCustomer(projectId: String, customerId: KeyValueModel, properties: [KeyValueModel])
    func trackEvents(projectId: String, customerId: KeyValueModel, properties: [KeyValueModel], timestamp: Int, eventType: String)
    func fetchTrackCustomer() -> [TrackCustomers]?
    func fetchTrackEvents() -> [TrackEvents]?
    func deleteTrackCustomer(object: AnyObject) -> Bool
    func deleteTrackEvent(object: AnyObject) -> Bool
}

/// The Entities Manager class is responsible for persist the data using CoreData Framework.
/// Persisted data will be used to interact with the Exponea API.
public class EntitiesManager {

    public lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "EntitiesModel")
        container.loadPersistentStores(completionHandler: { (_, error) in //(storeDescription, error) in
            if let error = error as NSError? {
                // TODO: Logging
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    /// Save all changes in CoreData
    public func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // TODO: Logging
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    /// Delete a specific object in CoreData
    private func deleteObject(_ object: NSManagedObject) {
        let context = persistentContainer.viewContext
        context.delete(object)
        saveContext()
    }
}

extension EntitiesManager: EntitieTrack {

    /// Update the Customer properties and persists it into the CoreData in the TrackCustomer Entity.
    ///
    /// - Parameters:
    ///     - projectId: Project token (you can find it in the Overview section of your project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - properties: Properties that should be updated
    public func trackCustomer(projectId: String, customerId: KeyValueModel, properties: [KeyValueModel]) {

        let trackCustomer = TrackCustomers(context: persistentContainer.viewContext)
        let trackCustomerProperties = TrackCustomersProperties(context: persistentContainer.viewContext)

        trackCustomer.projectId = projectId
        trackCustomer.customerIdKey = customerId.key
        trackCustomer.customerIdValue = customerId.value
        trackCustomer.timestamp = Int32(NSDate().timeIntervalSince1970)

        // Add the customer properties to the property entity
        for property in properties {
            trackCustomerProperties.key = property.key
            trackCustomerProperties.value = property.value

            trackCustomer.addToTrackCustomerProperties(trackCustomerProperties)
        }

        // Save the customer properties into CoreData
        saveContext()
    }

    /// Add events into a customer
    ///
    /// - Parameters:
    ///     - projectId: Project token (you can find it in the Overview section of your project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - properties: Properties that should be updated
    ///     - timestamp: Timestamp should always be UNIX timestamp format
    ///     - eventType: Type of event to be tracked
    public func trackEvents(projectId: String, customerId: KeyValueModel, properties: [KeyValueModel], timestamp: Int, eventType: String) {

        let trackEvents = TrackEvents(context: persistentContainer.viewContext)
        let trackEventsProperties = TrackEventsProperties(context: persistentContainer.viewContext)

        trackEvents.projectId = projectId
        trackEvents.timestamp = Int32(timestamp)
        trackEvents.eventType = eventType
        trackEvents.customerIdKey = customerId.key
        trackEvents.customerIdValue = customerId.value

        // Add the event properties to the events entity
        for property in properties {
            trackEventsProperties.key = property.key
            trackEventsProperties.value = property.value

            trackEvents.addToTrackEventsProperties(trackEventsProperties)
        }

        // Save the customer properties into CoreData
        saveContext()
    }

    /// Fetch all Tracking Customers from CoreData
    public func fetchTrackCustomer() -> [TrackCustomers]? {

        var trackCustomers = [TrackCustomers]()

        do {
            let context = persistentContainer.viewContext
            trackCustomers = try context.fetch(TrackCustomers.fetchRequest())
        } catch {
            // TODO: Logging
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
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
            // TODO: Logging
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }

        return trackEvents
    }

    /// Detele a Tracking Customer Object from CoreData
    ///
    /// - Parameters:
    ///     - object: Tracking Customer Object to be deleted from CoreData
    public func deleteTrackCustomer(object: AnyObject) -> Bool {

        guard let trackObject = object as? TrackCustomers else {
            // TODO: Logging
            return false
        }

        deleteObject(trackObject)
        return true
    }

    /// Detele a Tracking Event Object from CoreData
    ///
    /// - Parameters:
    ///     - object: Tracking Event Object to be deleted from CoreData
    public func deleteTrackEvent(object: AnyObject) -> Bool {

        guard let trackEvent = object as? TrackEvents else {
            // TODO: Logging
            return false
        }

        deleteObject(trackEvent)
        return true
    }
}
