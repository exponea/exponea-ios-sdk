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
class TrackEvent: NSManagedObjectWithContext, DatabaseObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TrackEvent> {
        let request = NSFetchRequest<TrackEvent>(entityName: "TrackEvent")
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(TrackEvent.timestamp), ascending: true)]
        return request
    }

    @NSManaged public var baseUrl: String?
    @NSManaged public var projectToken: String?
    @NSManaged public var authorizationString: String?

    @NSManaged public var eventType: String?
    @NSManaged public var timestamp: Double
    @NSManaged public var customer: Customer?
    @NSManaged public var retries: NSNumber
}

extension TrackEvent {

    var dataTypes: [DataType] {
        let data: [DataType]? = managedObjectContext?.performAndWait {
            var data: [DataType] = []

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

        return data ?? []
    }
}

// MARK: - Core Data -

extension TrackEvent: HasKeyValueProperties {
    @NSManaged public var properties: NSSet?

    @objc(addPropertiesObject:)
    @NSManaged public func addToProperties(_ value: KeyValueItem)

    @objc(removePropertiesObject:)
    @NSManaged public func removeFromProperties(_ value: KeyValueItem)

    @objc(addProperties:)
    @NSManaged public func addToProperties(_ values: NSSet)

    @objc(removeProperties:)
    @NSManaged public func removeFromProperties(_ values: NSSet)
}

final class TrackEventProxy: FlushableObject {
    let databaseObjectProxy: DatabaseObjectProxy

    let baseUrl: String?
    let projectToken: String?
    let authorization: Authorization

    let customerIds: [String: String]

    let eventType: String?
    let timestamp: TimeInterval
    let dataTypes: [DataType]

    init(_ event: TrackEvent) {
        self.databaseObjectProxy = DatabaseObjectProxy(event)
        self.baseUrl = event.baseUrl
        self.projectToken = event.projectToken
        self.authorization = Authorization(from: event.authorizationString)

        self.customerIds = event.customer?.ids ?? [:]

        self.eventType = event.eventType
        self.timestamp = event.timestamp
        self.dataTypes = event.dataTypes
    }

    func getTrackingObject(
        defaultBaseUrl: String,
        defaultProjectToken: String,
        defaultAuthorization: Authorization
    ) -> TrackingObject {
        var auth = authorization
        if case .none = auth {
            auth = defaultAuthorization
        }
        return EventTrackingObject(
            exponeaProject: ExponeaProject(
                baseUrl: baseUrl ?? defaultBaseUrl,
                projectToken: projectToken ?? defaultProjectToken,
                authorization: auth
            ),
            customerIds: customerIds,
            eventType: eventType,
            timestamp: timestamp,
            dataTypes: dataTypes
        )
    }
}
