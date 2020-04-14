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
    var customer: CustomerThreadSafe { get }

    func trackEvent(with data: [DataType], into project: ExponeaProject) throws
    func identifyCustomer(with data: [DataType], into project: ExponeaProject) throws
    func updateEvent(withId id: NSManagedObjectID, withData data: DataType) throws

    func fetchTrackCustomer() throws -> [TrackCustomerProxy]
    func fetchTrackEvent() throws -> [TrackEventProxy]

    func addRetry(_ object: DatabaseObjectProxy) throws

    func delete(_ object: DatabaseObjectProxy) throws

    /// Completely clears the database, including the Customer object.
    /// Useful for completely anonymizing the user.
    func clear() throws
}
