//
//  SessionManagerType.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 23/03/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation

protocol SessionManagerType {
    func applicationDidBecomeActive(at timestamp: TimeInterval)
    func applicationDidEnterBackground(at timestamp: TimeInterval)
    func doSessionTimeoutBackgroundWork(at timestamp: TimeInterval)

    // When reacting to delegates, we don't know if session was already started, we need to ensure that
    func ensureSessionStarted(at date: TimeInterval)

    func manualSessionStart(at date: TimeInterval)
    func manualSessionEnd(at date: TimeInterval)

    func clear()
}

extension SessionManagerType {
    func applicationDidBecomeActive() { applicationDidBecomeActive(at: Date().timeIntervalSince1970) }
    func applicationDidEnterBackground() { applicationDidEnterBackground(at: Date().timeIntervalSince1970) }
    func doSessionTimeoutBackgroundWork() { doSessionTimeoutBackgroundWork(at: Date().timeIntervalSince1970) }
    func ensureSessionStarted() { ensureSessionStarted(at: Date().timeIntervalSince1970) }
    func manualSessionStart() { manualSessionStart(at: Date().timeIntervalSince1970) }
    func manualSessionEnd() { manualSessionEnd(at: Date().timeIntervalSince1970) }
}

protocol SessionTrackingDelegate: class {
    func trackSessionStart(at timestamp: TimeInterval)
    func trackSessionEnd(at timestamp: TimeInterval, withDuration duration: TimeInterval)
}
