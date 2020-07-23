//
//  DatabaseManagerType.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 11/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import CoreData

/// Protocol to manage Tracking events
protocol DatabaseManagerType: class {
    var currentCustomer: CustomerThreadSafe { get }
    var customers: [CustomerThreadSafe] { get }

    func trackEvent(with data: [DataType], into project: ExponeaProject) throws
    func identifyCustomer(with data: [DataType], into project: ExponeaProject) throws
    func updateEvent(withId id: NSManagedObjectID, withData data: DataType) throws

    func fetchTrackCustomer() throws -> [TrackCustomerProxy]
    func countTrackCustomer() throws -> Int
    func fetchTrackEvent() throws -> [TrackEventProxy]
    func countTrackEvent() throws -> Int

    func addRetry(_ object: DatabaseObjectProxy) throws

    func delete(_ object: DatabaseObjectProxy) throws

    /// Creates new clear customer object. Useful for anonymizing the user.
    /// Existing events are tied to customer that was most recent when the event was created
    func makeNewCustomer()
}
