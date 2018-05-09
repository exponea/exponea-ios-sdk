//
//  TrackingManagerType.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 11/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

protocol TrackingManagerType: class {
    func track(_ type: EventType, with data: [DataType]?) throws

    // MARK: - Flushing -

    /// Flushing mode specifies how often and if should data be automatically flushed to Exponea.
    var flushingMode: FlushingMode { get set }
    /// This method can be used to manually flush all available data to Exponea.
    func flushData()
}
