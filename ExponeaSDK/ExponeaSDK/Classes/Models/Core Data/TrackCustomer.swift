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
        let request = NSFetchRequest<TrackCustomer>(entityName: "TrackCustomer")
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(TrackCustomer.timestamp), ascending: true)]
        return request
    }

    @NSManaged public var baseUrl: String?
    @NSManaged public var projectToken: String?
    @NSManaged public var authorizationString: String?

    @NSManaged public var timestamp: Double
    @NSManaged public var customer: Customer?
    @NSManaged public var retries: NSNumber

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
    let databaseObjectProxy: DatabaseObjectProxy

    let baseUrl: String?
    let projectToken: String?
    let authorization: Authorization

    let customerIds: [String: String]

    let timestamp: TimeInterval
    let dataTypes: [DataType]

    init(_ customer: TrackCustomer) {
        self.databaseObjectProxy = DatabaseObjectProxy(customer)
        self.baseUrl = customer.baseUrl
        self.projectToken = customer.projectToken
        self.authorization = Authorization(from: customer.authorizationString)

        self.customerIds = customer.customer?.ids ?? [:]

        self.timestamp = customer.timestamp
        self.dataTypes = customer.dataTypes
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
        return CustomerTrackingObject(
            exponeaProject: ExponeaProject(
                baseUrl: baseUrl ?? defaultBaseUrl,
                projectToken: projectToken ?? defaultProjectToken,
                authorization: auth
            ),
            customerIds: customerIds,
            timestamp: timestamp,
            dataTypes: dataTypes
        )
    }
}
