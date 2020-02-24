//
//  TrackCustomer+CoreDataClass.swift
//
//
//  Created by Dominik Hadl on 02/07/2018.
//
//

import Foundation
import CoreData

@objc(TrackCustomer)
class TrackCustomer: NSManagedObjectWithContext, DatabaseObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TrackCustomer> {
        return NSFetchRequest<TrackCustomer>(entityName: "TrackCustomer")
    }

    @NSManaged public var projectToken: String?
    @NSManaged public var timestamp: Double
    @NSManaged public var customer: Customer?
    @NSManaged public var retries: NSNumber

    var dataTypes: [DataType] {
        let data: [DataType]? = managedObjectContext?.performAndWait {
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

            return data
        }

        return data ?? []
    }
}

// MARK: - Core Data -

extension TrackCustomer: HasKeyValueProperties {
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

final class TrackCustomerProxy: FlushableObject {
    var trackingObject: TrackingObject { return customer }

    let customer: CustomerTrackingObject
    let databaseObjectProxy: DatabaseObjectProxy

    init(_ customer: TrackCustomer) {
        self.customer = CustomerTrackingObject(
            projectToken: customer.projectToken,
            timestamp: customer.timestamp,
            dataTypes: customer.dataTypes
        )
        self.databaseObjectProxy = DatabaseObjectProxy(customer)
    }
}
