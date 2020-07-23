//
//  Customer+CoreDataClass.swift
//
//
//  Created by Dominik Hadl on 02/07/2018.
//
//

import Foundation
import CoreData

@objc(Customer)
class Customer: NSManagedObjectWithContext {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Customer> {
        let request = NSFetchRequest<Customer>(entityName: "Customer")
        request.sortDescriptors = [NSSortDescriptor(key: "creationTimestamp", ascending: false)]
        return request
    }

    @NSManaged public var uuid: UUID
    @NSManaged public var creationTimestamp: TimeInterval
    @NSManaged public var pushToken: String?
    @NSManaged public var lastTokenTrackDate: Date?
    @NSManaged public var customIds: NSSet?
    @NSManaged public var trackCustomer: NSSet?
    @NSManaged public var trackEvent: NSSet?

    var ids: [String: String] {
        let ids: [String: String]? = managedObjectContext?.performAndWait {
            var data: [String: String] = ["cookie": uuid.uuidString]

            // Convert all properties to key value items.
            if let properties = customIds as? Set<KeyValueItem> {
                properties.forEach({
                    guard let key = $0.key, let object = $0.value else {
                        Exponea.logger.log(.warning, message: """
                            Skipping KeyValueItem with empty key (\($0.key ?? "N/A"))) \
                            or value (\(String(describing: $0.value))).
                            """)
                        return
                    }

                    guard let string = object as? NSString else {
                        Exponea.logger.log(.error, message: "Customer id is not NSString: \(object).")
                        return
                    }
                    data[key] = string as String
                })
            }
            return data
        }
        return ids ?? [:]
    }

    // https://stackoverflow.com/a/39239651/3179004 we need to expose superclass initializer for fetching
    @objc
    private override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

    init(uuid: UUID, context: NSManagedObjectContext) {
        super.init(context: context)
        self.uuid = uuid
        self.creationTimestamp = Date().timeIntervalSince1970
    }
}

// MARK: - CustomStringConvertible -

extension Customer {
    public override var description: String {
        var text = "[Customer]\n"

        // Add cookie, push token and last track date
        text += "UUID (cookie): \(uuid.uuidString)\n"
        text += "Created at: \(Date(timeIntervalSince1970: creationTimestamp))\n"
        text += "Push Token: \(pushToken ?? "N/A")\n"
        text += "Last Push Token Track Date: \(lastTokenTrackDate ?? Date.distantPast)"

        if let ids = customIds as? Set<KeyValueItem>, ids.count > 0 {
            text += "\nCustom IDs: "
            for id in ids {
                text += "\"\(String(describing: id.key))\" = \(String(describing: id.key)), "
            }
        }

        text += "\n"

        return text
    }
}

// MARK: - Core Data -

extension Customer {

    @objc(addCustomIdsObject:)
    @NSManaged public func addToCustomIds(_ value: KeyValueItem)

    @objc(removeCustomIdsObject:)
    @NSManaged public func removeFromCustomIds(_ value: KeyValueItem)

    @objc(addCustomIds:)
    @NSManaged public func addToCustomIds(_ values: NSSet)

    @objc(removeCustomIds:)
    @NSManaged public func removeFromCustomIds(_ values: NSSet)

}

extension Customer {

    @objc(addTrackCustomerObject:)
    @NSManaged public func addToTrackCustomer(_ value: TrackCustomer)

    @objc(removeTrackCustomerObject:)
    @NSManaged public func removeFromTrackCustomer(_ value: TrackCustomer)

    @objc(addTrackCustomer:)
    @NSManaged public func addToTrackCustomer(_ values: NSSet)

    @objc(removeTrackCustomer:)
    @NSManaged public func removeFromTrackCustomer(_ values: NSSet)

}

extension Customer {

    @objc(addTrackEventObject:)
    @NSManaged public func addToTrackEvent(_ value: TrackEvent)

    @objc(removeTrackEventObject:)
    @NSManaged public func removeFromTrackEvent(_ value: TrackEvent)

    @objc(addTrackEvent:)
    @NSManaged public func addToTrackEvent(_ values: NSSet)

    @objc(removeTrackEvent:)
    @NSManaged public func removeFromTrackEvent(_ values: NSSet)

}

class CustomerThreadSafe {
    public let managedObjectID: NSManagedObjectID
    public let uuid: UUID
    public let pushToken: String?
    public let lastTokenTrackDate: Date?
    public let ids: [String: String]

    init(_ customer: Customer) {
        managedObjectID = customer.objectID
        uuid = customer.uuid
        pushToken = customer.pushToken
        lastTokenTrackDate = customer.lastTokenTrackDate
        ids = customer.ids
    }
}

extension CustomerThreadSafe {
    func saveIdsToUserDefaults(appGroup: String) {
        guard let userDefaults = UserDefaults(suiteName: appGroup),
              let data = try? JSONEncoder().encode(ids) else {
            return
        }
        userDefaults.set(data, forKey: Constants.General.lastKnownCustomerIds)
    }
}
