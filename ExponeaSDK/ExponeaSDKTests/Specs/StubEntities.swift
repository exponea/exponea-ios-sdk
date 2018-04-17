//
//  StubEntities.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 17/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import CoreData

@testable import ExponeaSDK

class StubEntities {

    let container: NSPersistentContainer

    init(container: NSPersistentContainer) {
        self.container = container
    }

    func trackCustomers(projectToken: String,
                        timestamp: Double,
                        customerIdKey: String?,
                        customerIdValue: String? ) -> TrackCustomers? {
        let objct = NSEntityDescription.insertNewObject(forEntityName: "TrackCustomers",
                                                        into: container.viewContext)

        objct.setValue(projectToken, forKey: "projectToken")
        objct.setValue(timestamp, forKey: "timestamp")
        objct.setValue(customerIdKey, forKey: "customerIdKey")
        objct.setValue(customerIdValue, forKey: "customerIdValue")

        return objct as? TrackCustomers
    }

    func trackCustomersProperties(key: String,
                                  value: Any ) -> TrackCustomersProperties? {
        let objct = NSEntityDescription.insertNewObject(forEntityName: "TrackCustomersProperties",
                                                        into: container.viewContext)

        objct.setValue(key, forKey: "key")
        objct.setValue(value, forKey: "value")

        return objct as? TrackCustomersProperties
    }

    func trackEvents(projectToken: String,
                     timestamp: Double,
                     eventType: String,
                     customerIdKey: String?,
                     customerIdValue: String? ) -> TrackEvents? {
        let objct = NSEntityDescription.insertNewObject(forEntityName: "TrackEvents",
                                                        into: container.viewContext)

        objct.setValue(projectToken, forKey: "projectToken")
        objct.setValue(timestamp, forKey: "timestamp")
        objct.setValue(eventType, forKey: "eventType")
        objct.setValue(customerIdKey, forKey: "customerIdKey")
        objct.setValue(customerIdValue, forKey: "customerIdValue")

        return objct as? TrackEvents
    }

    func trackEventsProperties(key: String,
                               value: Any ) -> TrackEventsProperties? {
        let objct = NSEntityDescription.insertNewObject(forEntityName: "TrackEventsProperties",
                                                        into: container.viewContext)

        objct.setValue(key, forKey: "key")
        objct.setValue(value, forKey: "value")

        return objct as? TrackEventsProperties
    }
}
