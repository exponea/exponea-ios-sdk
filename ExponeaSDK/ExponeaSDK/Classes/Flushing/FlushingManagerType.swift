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
    func flushData(completion: (() -> Void)?)

    func flushDataWith(delay: Double, completion: (() -> Void)?)

    func applicationDidBecomeActive()

    func applicationDidEnterBackground()
}

extension FlushingManagerType {
    func flushData() {
        flushData(completion: nil)
    }

    func flushDataWith(delay: Double) {
        flushDataWith(delay: delay, completion: nil)
    }
}
