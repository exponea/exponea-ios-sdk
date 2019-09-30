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
public protocol DatabaseManagerType: class {
    var customer: CustomerThreadSafe { get }
    
    func trackEvent(with data: [DataType]) throws
    func identifyCustomer(with data: [DataType]) throws
    func updateEvent(withId id: NSManagedObjectID, withData data: DataType) throws
    
    func fetchTrackCustomer() throws -> [TrackCustomerThreadSafe]
    func fetchTrackEvent() throws -> [TrackEventThreadSafe]

    func addRetry(_ object: TrackCustomerThreadSafe) throws
    func addRetry(_ object: TrackEventThreadSafe) throws

    func delete(_ object: TrackCustomerThreadSafe) throws
    func delete(_ object: TrackEventThreadSafe) throws

    /// Completely clears the database, including the Customer object.
    /// Useful for completely anonymizing the user.
    func clear() throws
}
