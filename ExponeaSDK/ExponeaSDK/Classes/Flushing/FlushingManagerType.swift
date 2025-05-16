//
//  FlushingManagerType.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 13/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

protocol FlushingManagerType {
    /// Flushing mode specifies how often and if should data be automatically flushed to Exponea.
    /// See `FlushingMode` for available values.
    var flushingMode: FlushingMode { get set }

    /// This method can be used to manually flush all available data to Exponea.
    func flushData(isFromIdentify: Bool, completion: ((FlushResult) -> Void)?)

    func flushDataWith(delay: Double, completion: ((FlushResult) -> Void)?)

    func applicationDidBecomeActive()

    func applicationDidEnterBackground()

    /// Returns true if event database contains data that needs to be flushed to exponea servers
    func hasPendingData() -> Bool
    var inAppRefreshCallback: EmptyBlock? { get set }
}

/// Result of flushing operation
public enum FlushResult {
    // Success with number of event/customer identification objects flushed.
    case success(Int)
    // Flush can only be running once at a time.
    case flushAlreadyInProgress
    // Unable to flush, we're not connected to internet
    case noInternetConnection
    // Unexpected error occured during flushing
    case error(Error)
}

extension FlushingManagerType {
    func flushData() {
        flushData(isFromIdentify: false, completion: nil)
    }
    
    func flushData(isFromIdentify: Bool = false, completion: ((FlushResult) -> Void)? = nil) {
        flushData(isFromIdentify: isFromIdentify, completion: completion)
    }

    func flushDataWith(delay: Double) {
        flushDataWith(delay: delay, completion: nil)
    }
}
