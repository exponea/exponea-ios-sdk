//
//  ExponeaInternal+Tracking.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 28/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import UserNotifications

extension ExponeaInternal {
    /// Adds new events to a customer. All events will be stored into coredata
    /// until it will be flushed (send to api).
    ///
    /// - Parameters:
    ///     - properties: Object with event values.
    ///     - timestamp: Unix timestamp when the event was created.
    ///     - eventType: Name of event
    public func trackEvent(properties: [String: JSONConvertible], timestamp: Double?, eventType: String?) {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient
            }
            var data: [DataType] = [.properties(properties.mapValues({ $0.jsonValue })), .timestamp(timestamp)]

            // If event type was provided, use it
            if let eventType = eventType {
                data.append(.eventType(eventType))
            }

            // Do the actual tracking
            try dependencies.trackingManager.track(.customEvent, with: data)
        }
    }

    /// Adds new payment event to a customer.
    ///
    /// - Parameters:
    ///     - properties: Object with event values.
    ///     - timestamp: Unix timestamp when the event was created.
    public func trackPayment(properties: [String: JSONConvertible], timestamp: Double?) {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient
            }
            let data: [DataType] = [.properties(properties.mapValues({ $0.jsonValue })), .timestamp(timestamp)]

            // Do the actual tracking
            try dependencies.trackingManager.track(.payment, with: data)
        }
    }

    /// Update the informed properties to a specific customer.
    /// All properties will be stored into coredata until it will be flushed (send to api).
    ///
    /// - Parameters:
    ///     - customerId: Specify your customer with external id, for example an email address.
    ///     - properties: Object with properties to be updated.
    ///     - timestamp: Unix timestamp when the event was created.
    public func identifyCustomer(customerIds: [String: String]?,
                                 properties: [String: JSONConvertible],
                                 timestamp: Double?) {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient
            }
            var data: [DataType] = [.properties(properties.mapValues({ $0.jsonValue })), .timestamp(timestamp)]
            if var ids = customerIds {
                // Check for overriding cookie
                if ids["cookie"] != nil {
                    ids.removeValue(forKey: "cookie")
                    Exponea.logger.log(.warning, message: """
                    You should never set cookie ID directly on a customer. Ignoring.
                    """)
                }
                data.append(.customerIds(ids))
            }

            try dependencies.trackingManager.track(.identifyCustomer, with: data)
        }
    }

    // MARK: Push Notifications

    /// Tracks the push notification token to Exponea API with struct.
    ///
    /// - Parameter token: Token data.
    public func trackPushToken(_ token: Data) {
        // Convert token data to String
        trackPushToken(token.tokenString)
    }

    /// Tracks the push notification token to Exponea API with string.
    ///
    /// - Parameter token: String containing the push notification token.
    public func trackPushToken(_ token: String?) {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient
            }
            UNAuthorizationStatusProvider.current.isAuthorized { authorized in
                let data: [DataType] = [.pushNotificationToken(token: token, authorized: authorized)]
                // Do the actual tracking
                self.executeSafely {
                    try dependencies.trackingManager.track(.identifyCustomer, with: data)
                }
            }
        }
    }

    /// Tracks the push notification clicked event to Exponea API.
    public func trackPushOpened(with userInfo: [AnyHashable: Any]) {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient
            }

            guard let payload = userInfo as? [String: Any] else {
                Exponea.logger.log(.error, message: "Push notification payload contained non-string keys.")
                return
            }

            var properties = JSONValue.convert(payload)
            if properties.index(forKey: "action_type") == nil {
                properties["action_type"] = .string("mobile notification")
            }
            properties["status"] = .string("clicked")

            let data: [DataType] = [.timestamp(nil), .properties(properties)]
            // Do the actual tracking
            try dependencies.trackingManager.track(.pushOpened, with: data)
        }
    }

    // MARK: Sessions
    public func trackSessionStart() {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient
            }
            dependencies.trackingManager.manualSessionStart()
        }
    }

    public func trackSessionEnd() {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient
            }
            dependencies.trackingManager.manualSessionEnd()
        }
    }

    // MARK: Campaign data

    internal func processSavedCampaignData() {
        guard var events = self.userDefaults.array(forKey: Constants.General.savedCampaignClickEvent) as? [Data] else {
            return
        }
        trackLastCampaignEvent(events.popLast())
        trackOtherCampaignEvents(events)
        // remove all stored events if processed
        userDefaults.removeObject(forKey: Constants.General.savedCampaignClickEvent)
    }

    // last registered campaign click should be appended to session start event
    private func trackLastCampaignEvent(_ lastEvent: Data?) {
        if let lastEvent = lastEvent,
            let campaignData = try? JSONDecoder().decode(CampaignData.self, from: lastEvent) {
            trackCampaignData(data: campaignData, timestamp: nil)
        }
    }

    // older events will not update session
    private func trackOtherCampaignEvents(_ events: [Data]) {
        executeSafelyWithDependencies { dependencies in
            try events.forEach { event in
                guard let campaignData = try? JSONDecoder().decode(CampaignData.self, from: event) else {
                    return
                }
                var properties = campaignData.trackingData
                properties["platform"] = .string("ios")
                // url and payload is required for campaigns, but missing in notifications
                if campaignData.url != nil && campaignData.payload != nil {
                    try dependencies.trackingManager.track(.campaignClick, with: [.properties(properties)])
                }
            }
        }
    }

    private func saveCampaignData(campaignData: CampaignData) {
        var events = userDefaults.array(forKey: Constants.General.savedCampaignClickEvent) ?? []
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(campaignData) {
            events.append(encoded)
        }
        userDefaults.set(events, forKey: Constants.General.savedCampaignClickEvent)
    }

    public func trackCampaignClick(url: URL, timestamp: Double?) {
        trackCampaignData(data: CampaignData(url: url), timestamp: timestamp)
    }

    func trackCampaignData(data: CampaignData, timestamp: Double?) {
        Exponea.logger.log(.verbose, message: "Tracking campaign data: \(data.description)")
        if !isConfigured {
            saveCampaignData(campaignData: data)
            return
        }
        executeSafelyWithDependencies { dependencies in
            // Create initial data
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient
            }
            // Do the actual tracking
            var properties = data.trackingData
            properties["platform"] = .string("ios")
            // url and payload is required for campaigns, but missing in notifications
            if data.url != nil && data.payload != nil {
                try dependencies.trackingManager.track(.campaignClick, with: [.properties(properties)])
            }
            if dependencies.configuration.automaticSessionTracking {
                // Campaign click should result in new session, unless there is an active session
                dependencies.trackingManager.ensureAutomaticSessionStarted()
                // If the session was tracked before tracking campaign click, amend it
                if try dependencies.trackingManager.hasPendingEvent(ofType: Constants.EventTypes.sessionStart,
                                                                withMaxAge: Constants.Session.sessionUpdateThreshold) {
                    Exponea.logger.log(.verbose, message: "Amending session start event with campaign data")
                    try dependencies.trackingManager.updateLastPendingEvent(
                        ofType: Constants.EventTypes.sessionStart,
                        with: .properties(data.trackingData)
                    )
                }
            }
        }
    }

    /// Handles push notification opened - user action for alert notifications, delivery into app for silent pushes.
    /// This method will parse the data, track it and perform actions if needed.
    public func handlePushNotificationOpened(response: UNNotificationResponse) {
        handlePushNotificationOpened(
            userInfo: response.notification.request.content.userInfo,
            actionIdentifier: response.actionIdentifier
        )
    }

    /// Handles push notification opened - user action for alert notifications, delivery into app for silent pushes.
    /// This method will parse the data, track it and perform actions if needed.
    public func handlePushNotificationOpened(userInfo: [AnyHashable: Any], actionIdentifier: String? = nil) {
        guard Exponea.isExponeaNotification(userInfo: userInfo) else {
            Exponea.logger.log(.verbose, message: "Skipping non-Exponea notification")
            return
        }
        // if the SDK is not configured, we should save the notification for later processing
        guard isConfigured else {
            Exponea.logger.log(.verbose, message: "Exponea not configured yet, saving opened push.")
            PushNotificationManager.storePushOpened(
                userInfoObject: userInfo as AnyObject?,
                actionIdentifier: actionIdentifier,
                timestamp: Date().timeIntervalSince1970
            )
            return
        }
        executeSafelyWithDependencies { dependencies in
            dependencies.trackingManager.notificationsManager.handlePushOpened(
                userInfoObject: userInfo as AnyObject?,
                actionIdentifier: actionIdentifier
            )
        }
    }

    /// Handles push notification token registration - compared to trackPushToken respects requirePushAuthorization
    public func handlePushNotificationToken(deviceToken: Data) {
        executeSafelyWithDependencies { dependencies in
            dependencies.trackingManager.notificationsManager.handlePushTokenRegistered(
                dataObject: deviceToken as AnyObject?
            )
        }
    }

    // MARK: Flushing
    /// This method can be used to manually flush all available data to Exponea.
    public func flushData() {
        flushData(completion: nil)
    }

    /// This method can be used to manually flush all available data to Exponea.
    public func flushData(completion: ((FlushResult) -> Void)?) {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient
            }
            dependencies.flushingManager.flushData(completion: completion)
        }
    }

    // MARK: Anonymize

    /// Anonymizes the user and starts tracking as if the app was just installed.
    /// All customer identification (including cookie) will be permanently deleted.
    public func anonymize() {
        executeSafelyWithDependencies { dependencies in
            anonymize(
                exponeaProject: dependencies.configuration.mainProject,
                projectMapping: dependencies.configuration.projectMapping
            )
        }
    }

    /// Anonymizes the user and starts tracking as if the app was just installed.
    /// All customer identification (including cookie) will be permanently deleted.
    /// Switches tracking into provided exponeaProject
    public func anonymize(exponeaProject: ExponeaProject, projectMapping: [EventType: [ExponeaProject]]?) {
        executeSafelyWithDependencies { dependencies in
            try dependencies.trackingManager.anonymize(
                exponeaProject: exponeaProject,
                projectMapping: projectMapping
            )
            telemetryManager?.report(eventWithType: .anonymize, properties: [:])
        }
    }
}
