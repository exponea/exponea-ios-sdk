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
    func trackCustumer(projectId: String, customerId: KeyValueModel, properties: [KeyValueModel])
    func trackEvents(projectId: String, customerId: KeyValueModel, properties: [KeyValueModel], timestamp: Int, eventType: String)
}

/// Protocol to manage manipulate private Tokens
public protocol EntitieTokens: class {
    func rotateToken(projectId: String)
    func revokeToken(projectId: String)
}

/// Protocol to manage and modify the customer data
public protocol EntitieCustomerData: class {
    func anonymize(projectId: String, customerId: KeyValueModel)
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
}

extension EntitiesManager: EntitieTrack {

    /// Update the Customer properties and persists it into the CoreData in the TrackCustomer Entity.
    ///
    /// - Parameters:
    ///     - projectId: Project token (you can find it in the Overview section of your project)
    ///     - customerId: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    ///     - properties: Properties that should be updated
    public func trackCustumer(projectId: String, customerId: KeyValueModel, properties: [KeyValueModel]) {

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
}

extension EntitiesManager: EntitieTokens {

    /// To rotate your private token just post an empty JSON to the following route.
    /// The old token will still work for next 48 hours. You cannot have more than two
    /// private tokens for one public token, therefore rotating the newly fetched token
    /// while the old token is still working will result in revoking that old token right away.
    /// Rotating the old token twice will result in error, since you cannot have three tokens at the same time.
    ///
    /// - Parameters:
    ///     - projectId: Project token (you can find it in the Overview section of your project)
    public func rotateToken(projectId: String) {

        let tokenRotate = TokenRotate(context: persistentContainer.viewContext)

        tokenRotate.projectId = projectId
        tokenRotate.timestamp = Int32(NSDate().timeIntervalSince1970)

        // Save the Rotate Token into CoreData
        saveContext()
    }

    /// To revoke token right away just post an empty JSON to the following route.
    /// Please note, that revoking a token can result in losing the access if you haven't revoked a new token before.
    ///
    /// - Parameters:
    ///     - projectId: Project token (you can find it in the Overview section of your project)
    public func revokeToken(projectId: String) {

        let tokenRevoke = TokenRevoke(context: persistentContainer.viewContext)

        tokenRevoke.projectId = projectId
        tokenRevoke.timestamp = Int32(NSDate().timeIntervalSince1970)

        // Save the Revoke Token into CoreData
        saveContext()
    }
}

extension EntitiesManager: EntitieCustomerData {

    /// Removes all the external identifiers and assigns a new cookie id. Removes all personal customer properties
    ///
    /// - Parameters:
    ///     - projectId: Project token (you can find it in the Overview section of your project)
    ///     - customerIds: “cookie” for identifying anonymous customers or “registered” for identifying known customers)
    public func anonymize(projectId: String, customerId: KeyValueModel) {

        let customerAnonymize = CustomerAnonymize(context: persistentContainer.viewContext)

        customerAnonymize.projectId = projectId
        customerAnonymize.customerIdKey = customerId.key
        customerAnonymize.customerIdValue = customerId.value
    }
}
