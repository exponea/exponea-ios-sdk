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
class DatabaseManager {
    internal let persistentContainer: NSPersistentContainer
    private let context: NSManagedObjectContext

    internal init(persistentStoreDescriptions: [NSPersistentStoreDescription]? = nil) throws {
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle(for: DatabaseManager.self)
        #endif

        guard let container = NSPersistentContainer(name: "DatabaseModel", bundle: bundle) else {
            throw DatabaseManagerError.unableToCreatePersistentContainer
        }
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

        // Set the container
        persistentContainer = container
        context = persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy

        // Initialise customer
        _ = currentCustomer
        Exponea.logger.log(.verbose, message: "Database initialised with customer:\n\(currentCustomer)")
    }
}

extension DatabaseManager {
    /**
     We'll wrap context saving to catch common errors and handle them in one place.
     In case of a full disk, there is nothing we can do, so just log error.
     */
    private func saveContext(_ context: NSManagedObjectContext) throws {
        do {
            try context.save()
        } catch let diskError as NSError // SQLITE code 13 means full disk http://www.sqlite.org/c3ref/c_abort.html
                where diskError.domain == NSSQLiteErrorDomain && diskError.code == 13 {
            let error = DatabaseManagerError.notEnoughDiskSpace(diskError.localizedDescription)
            Exponea.logger.log(.error, message: error.localizedDescription)
        }
    }

    public var currentCustomer: CustomerThreadSafe {
        return context.performAndWait {
            return CustomerThreadSafe(currentCustomerManagedObject)
        }
    }

    private var currentCustomerManagedObject: Customer {
        return context.performAndWait {
            do {
                let customers: [Customer] = try context.fetch(Customer.fetchRequest())
                // If we have customer return it, otherwise create a new one
                if let currentCustomer = customers.first {
                    // if older customers don't have any events assigned to them, delete them
                    for (index, customer) in customers.enumerated() {
                        if index == 0 { continue }
                        if customer.trackCustomer?.count == 0 && customer.trackEvent?.count == 0 {
                            try? delete(customer.objectID)
                        }
                    }
                    return currentCustomer
                }
            } catch {
                Exponea.logger.log(.warning, message: "No customer found saved in database, will create. \(error)")
            }
            return makeNewCustomerInternal()
        }
    }

    private func makeNewCustomerInternal() -> Customer {
        return context.performAndWait {
            let customer = Customer(uuid: UUID(), context: context)
            context.insert(customer)

            do {
                try saveContext(context)
                Exponea.logger.log(.verbose, message: "New customer created with UUID: \(customer.uuid)")
            } catch let saveError as NSError {
                let error = DatabaseManagerError.saveCustomerFailed(saveError.localizedDescription)
                Exponea.logger.log(.error, message: error.localizedDescription)
            } catch {
                Exponea.logger.log(.error, message: error.localizedDescription)
            }

            return customer
        }
    }

    func makeNewCustomer() {
        _ = makeNewCustomerInternal()
    }

    /// Just list all customers in db. Mainly for debugging and testing
    var customers: [CustomerThreadSafe] {
        return context.performAndWait {
            do {
                let customers: [Customer] = try context.fetch(Customer.fetchRequest())
                return customers.map { CustomerThreadSafe($0) }
            } catch {
                Exponea.logger.log(.warning, message: "Error while fetching all customers. \(error)")
                return []
            }
        }
    }

    private func fetchCurrentCustomerAndUpdate(with ids: [String: String]) -> Customer {
        return context.performAndWait {
            let customer = self.currentCustomerManagedObject

            // Add the ids to the customer entity
            for id in ids {
                // Check if we have existing
                if let item = customer.customIds?.first(where: { (existing) -> Bool in
                    guard let existing = existing as? KeyValueItem else { return false }
                    return existing.key == id.key
                }) as? KeyValueItem {
                    // Update value, since it has changed
                    item.value = NSString(string: id.value)
                    Exponea.logger.log(.verbose, message: """
                        Updating value of existing customerId (\(id.key)) with value: \(id.value).
                        """)
                } else {
                    // Create item and insert it
                    let item = KeyValueItem(context: context)
                    item.key = id.key
                    item.value = NSString(string: id.value)
                    context.insert(item)
                    customer.addToCustomIds(item)

                    Exponea.logger.log(.verbose, message: """
                        Creating new customerId (\(id.key)) with value: \(id.value).
                        """)
                }
            }

            do {
                // We don't know if anything changed
                if context.hasChanges {
                    try saveContext(context)
                }
            } catch {
                let error = DatabaseManagerError.saveCustomerFailed(error.localizedDescription)
                Exponea.logger.log(.error, message: error.localizedDescription)
            }

            return customer
        }
    }

    private func fetchCurrentCustomerAndUpdate(pushToken: String?) -> Customer {
        return context.performAndWait {
            let customer = self.currentCustomerManagedObject

            // Update push token and last token track date
            customer.pushToken = pushToken
            customer.lastTokenTrackDate = .init()

            do {
                // We don't know if anything changed
                if context.hasChanges {
                    try saveContext(context)
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
    func updateEvent(withId id: NSManagedObjectID, withData data: DataType) throws {
        try context.performAndWait {
            guard let object = try? context.existingObject(with: id) else {
                throw DatabaseManagerError.objectDoesNotExist
            }
            guard let event = object as? TrackEvent else {
                throw DatabaseManagerError.wrongObjectType
            }
            switch data {
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
            try saveContext(context)
        }
    }

    /// Add any type of event into coredata.
    ///
    /// - Parameter data: See `DataType` for more information. Types specified below are required at minimum.
    ///     - `customerId`
    ///     - `properties`
    ///     - `timestamp`
    ///     - `eventType`
    func trackEvent(with data: [DataType], into project: ExponeaProject) throws {
        try context.performAndWait {
            let trackEvent = TrackEvent(context: context)
            trackEvent.customer = currentCustomerManagedObject

            // Always specify a timestamp
            if trackEvent.eventType == Constants.EventTypes.pushOpen
                || trackEvent.eventType == Constants.EventTypes.pushDelivered {
                trackEvent.timestamp = data.latestTimestamp ?? Date().timeIntervalSince1970
            } else {
                trackEvent.timestamp = Date().timeIntervalSince1970
            }
            trackEvent.baseUrl = project.baseUrl
            trackEvent.projectToken = project.projectToken
            trackEvent.authorizationString = project.authorization.encode()
            for type in data {
                switch type {
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

            Exponea.logger.log(
                .verbose,
                message: "Adding track event \(trackEvent.eventType ?? "nil") to database: \(trackEvent.objectID)"
            )

            // Save the customer properties into CoreData
            try saveContext(context)
        }
    }

    /// Add customer properties into the database.
    ///
    /// - Parameter data: See `DataType` for more information. Types specified below are required at minimum.
    ///     - `customerId`
    ///     - `properties`
    ///     - `timestamp`
    /// - Throws: <#throws value description#>
    func identifyCustomer(with data: [DataType], into project: ExponeaProject) throws {
        try context.performAndWait {
            let trackCustomer = TrackCustomer(context: context)
            trackCustomer.customer = currentCustomerManagedObject

            // Always specify a timestamp
            trackCustomer.timestamp = Date().timeIntervalSince1970
            trackCustomer.baseUrl = project.baseUrl
            trackCustomer.projectToken = project.projectToken
            trackCustomer.authorizationString = project.authorization.encode()

            for type in data {
                switch type {
                case .customerIds(let ids):
                    trackCustomer.customer = fetchCurrentCustomerAndUpdate(with: ids)

                case .timestamp(let time):
                    trackCustomer.timestamp = time ?? trackCustomer.timestamp

                case .properties(let properties):
                    // Add the customer properties to the customer entity
                    processProperties(properties, into: trackCustomer)

                case .pushNotificationToken(let token, let authorized):
                    let tokenItem = KeyValueItem(context: context)
                    tokenItem.key = "apple_push_notification_id"
                    tokenItem.value = (token ?? "") as NSString
                    trackCustomer.addToProperties(tokenItem)

                    let authorizatedItem = KeyValueItem(context: context)
                    authorizatedItem.key = "apple_push_notification_authorized"
                    authorizatedItem.value = authorized as NSObject
                    trackCustomer.addToProperties(authorizatedItem)

                    // Update push token on customer
                    trackCustomer.customer = fetchCurrentCustomerAndUpdate(pushToken: token)

                default:
                    break
                }
            }

            // Save the customer properties into CoreData
            try saveContext(context)
        }
    }

    /// <#Description#>
    ///
    /// - Parameters:
    ///   - properties: <#properties description#>
    ///   - object: <#object description#>
    func processProperties(
        _ properties: [String: JSONValue],
        into object: HasKeyValueProperties
    ) {
        for property in properties {
            let existingProperties = object.properties as? Set<KeyValueItem>
            if let existingProperty: KeyValueItem = existingProperties?.first(where: { $0.key == property.key }) {
                existingProperty.value = property.value.objectValue
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
    func fetchTrackCustomer() throws -> [TrackCustomerProxy] {
        return try context.performAndWait {
            let trackCustomerEvents: [TrackCustomer] = try context.fetch(TrackCustomer.fetchRequest())
            return trackCustomerEvents.map { TrackCustomerProxy($0) }
        }
    }

    func countTrackCustomer() throws -> Int {
        return try context.performAndWait {
            try context.count(for: TrackCustomer.fetchRequest())
        }
    }

    /// Fetch all Tracking Events from CoreData
    ///
    /// - Returns: An array of tracking events, if any are stored in the database.
    func fetchTrackEvent() throws -> [TrackEventProxy] {
        return try context.performAndWait {
            let trackEvents: [TrackEvent] = try context.fetch(TrackEvent.fetchRequest())
            return trackEvents.map { TrackEventProxy($0) }
        }
    }

    func countTrackEvent() throws -> Int {
        return try context.performAndWait {
            try context.count(for: TrackEvent.fetchRequest())
        }
    }

    func addRetry(_ databaseObjectProxy: DatabaseObjectProxy) throws {
        try context.performAndWait {
            guard let object = try? context.existingObject(with: databaseObjectProxy.objectID) else {
                throw DatabaseManagerError.objectDoesNotExist
            }
            guard var databaseObject: DatabaseObject = object as? DatabaseObject else {
                throw DatabaseManagerError.objectDoesNotExist
            }
            databaseObject.retries = NSNumber(value: databaseObjectProxy.retries + 1)
            try saveContext(context)
        }
    }

    func delete(_ databaseObjectProxy: DatabaseObjectProxy) throws {
        try delete(databaseObjectProxy.objectID)
    }

    private func delete(_ objectID: NSManagedObjectID) throws {
        try context.performAndWait {
            guard let object = try? context.existingObject(with: objectID) else {
                return
            }
            context.delete(object)
            try saveContext(context)
        }
    }
}
