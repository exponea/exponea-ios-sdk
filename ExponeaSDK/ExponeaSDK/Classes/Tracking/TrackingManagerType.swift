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
    var customerIds: [String: String] { get }

    /// Cookie of the current customer.
    var customerCookie: String { get }

    /// Returns the push token of the current customer if there is any.
    var customerPushToken: String? { get }

    /// The manager responsible for handling notification callbacks.
    var notificationsManager: PushNotificationManagerType { get }

    /// Main function used to track events to Exponea.
    ///
    /// - Parameters:
    ///   - type: Type of the event you want to track. Please, see `EventType` for more information.
    ///   - data: Data associated with this particular event that should be tracked along.
    /// - Throws: An error of type `TrackingManagerError`.
    func track(_ type: EventType, with data: [DataType]?) throws

    /// Updates last pending(not yet sent to server) event for all project tokens
    /// - type: Type of event you want to update.
    /// - data: update data
    func updateLastPendingEvent(ofType type: String, with data: DataType) throws

    /// Returns true if there is a pending(not yet sent to server) event that is newer than `age`
    func hasPendingEvent(ofType type: String, withMaxAge age: Double) throws -> Bool

    // When reacting to delegates, we don't know if session was already started, we need to ensure that
    func ensureAutomaticSessionStarted()

    func manualSessionStart()
    func manualSessionEnd()

    /// Anonymizes the user by deleting all identifiers (including cookie) and deletes all database data.
    /// You can switch project and new user will be tracked into it
    func anonymize(exponeaProject: ExponeaProject, projectMapping: [EventType: [ExponeaProject]]?) throws
}
