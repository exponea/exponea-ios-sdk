//
//  TrackingManagerType.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 11/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// Class of type `TrackingManagerType` is responsible for all event and customer tracking.
protocol TrackingManagerType: class {
    
    /// The identifiers of the the current customer.
    var customerIds: [AnyHashable: JSONConvertible] { get }
    
    /// Main function used to track events to Exponea.
    ///
    /// - Parameters:
    ///   - type: Type of the event you want to track. Please, see `EventType` for more information.
    ///   - data: Data associated with this particular event that should be tracked along.
    /// - Throws: An error of type `TrackingManagerError`.
    func track(_ type: EventType, with data: [DataType]?) throws

    // MARK: - Flushing -

    /// Flushing mode specifies how often and if should data be automatically flushed to Exponea.
    /// See `FlushingMode` for available values.
    var flushingMode: FlushingMode { get set }
    
    /// This method can be used to manually flush all available data to Exponea.
    func flushData()
}
