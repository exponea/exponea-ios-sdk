//
//  Exponea+Tracking.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 28/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

extension Exponea {
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
                throw ExponeaError.authorizationInsufficient("token, basic")
            }

            // Retrieve the default properties to add on track events and combine with the received ones.
            let defaultProperties = dependencies.configuration.defaultProperties ?? [:]
            let allProperties = defaultProperties.merging(properties, uniquingKeysWith: { (_, new) in new })

            // Create initial data
            var data: [DataType] = [.properties(allProperties.mapValues({ $0.jsonValue })),
                                    .timestamp(timestamp)]

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
                throw ExponeaError.authorizationInsufficient("token, basic")
            }

            // Retrieve the default properties to add on track events and combine with the received ones.
            let defaultProperties = dependencies.configuration.defaultProperties ?? [:]
            let allProperties = defaultProperties.merging(properties, uniquingKeysWith: { (_, new) in new })

            // Create initial data
            let data: [DataType] = [.properties(allProperties.mapValues({ $0.jsonValue })),
                                    .timestamp(timestamp)]

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
    public func identifyCustomer(customerIds: [String: JSONConvertible]?,
                                 properties: [String: JSONConvertible],
                                 timestamp: Double?) {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient("token, basic")
            }

            // Retrieve the default properties to add on track events and combine with the received ones.
            let defaultProperties = dependencies.configuration.defaultProperties ?? [:]
            let allProperties = defaultProperties.merging(properties, uniquingKeysWith: { (_, new) in new })

            // Prepare data
            var data: [DataType] = [.properties(allProperties.mapValues({ $0.jsonValue })),
                                    .timestamp(timestamp)]
            if var ids = customerIds {
                // Check for overriding cookie
                if ids["cookie"] != nil {
                    ids.removeValue(forKey: "cookie")
                    Exponea.logger.log(.warning, message: """
                    You should never set cookie ID directly on a customer. Ignoring.
                    """)
                }

                data.append(.customerIds(ids.mapValues({ $0.jsonValue })))
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
                throw ExponeaError.authorizationInsufficient("token, basic")
            }
            let data: [DataType] = [.pushNotificationToken(token)]

            // Do the actual tracking
            try dependencies.trackingManager.track(.identifyCustomer, with: data)
        }
    }

    /// Tracks the push notification clicked event to Exponea API.
    public func trackPushOpened(with userInfo: [AnyHashable: Any]) {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient("token, basic")
            }

            guard let payload = userInfo as? [String: Any] else {
                Exponea.logger.log(.error, message: "Push notification payload contained non-string keys.")
                return
            }

            // Retrieve the default properties to add on track events and combine with the received ones.
            let defaultProperties = dependencies.configuration.defaultProperties?.mapValues { $0.jsonValue } ?? [:]

            var properties = JSONValue.convert(payload)
            if properties.index(forKey: "action_type") == nil {
                properties["action_type"] = .string("mobile notification")
            }
            properties["status"] = .string("clicked")

            let allProperties = defaultProperties.merging(properties, uniquingKeysWith: { (_, new) in new })

            let data: [DataType] = [.timestamp(nil),
                                    .properties(allProperties)]
            // Do the actual tracking
            try dependencies.trackingManager.track(.pushOpened, with: data)
        }
    }

    // MARK: Sessions

    public func trackSessionStart() {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient("token, basic")
            }
            try dependencies.trackingManager.triggerSessionStart()
        }
    }

    /// Tracks a
    public func trackSessionEnd() {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient("token, basic")
            }
            try dependencies.trackingManager.triggerSessionEnd()
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
            trackCampaignClick(url: campaignData.url, timestamp: nil)
        }
    }

    // older events will not update session
    private func trackOtherCampaignEvents(_ events: [Data]) {
        for event in events {
            guard let campaignData = try? JSONDecoder().decode(CampaignData.self, from: event),
                  let campaignDataProperties = campaignData.campaignData as? [String: JSONConvertible] else {
                continue
            }
            trackEvent(
                properties: campaignDataProperties,
                timestamp: campaignData.timestamp,
                eventType: Constants.EventTypes.campaignClick
            )
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
        let data = CampaignData(url: url)
        Exponea.logger.log(.verbose, message: "Link Open event registred for path : \(url.description)")
        if !isConfigured {
            saveCampaignData(campaignData: data)
            return
        }
        executeSafelyWithDependencies { dependencies in
            // Create initial data
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient("token")
            }
            // Do the actual tracking
            try dependencies.trackingManager.track(.campaignClick, with: [data.campaignDataProperties])
            if dependencies.configuration.automaticSessionTracking {
                // Campaign click should result in new session, unless there is an active session
                if !dependencies.trackingManager.hasActiveSession {
                    Exponea.logger.log(.verbose, message: "Triggering session start for campaign click")
                    try dependencies.trackingManager.triggerSessionStart()
                }
                // If the session was tracked before tracking campaign click, amend it
                if try dependencies.trackingManager.hasPendingEvent(ofType: Constants.EventTypes.sessionStart,
                                                                withMaxAge: Constants.Session.sessionUpdateThreshold) {
                    Exponea.logger.log(.verbose, message: "Amending session start event with campaign data")
                    try dependencies.trackingManager.updateLastPendingEvent(
                        ofType: Constants.EventTypes.sessionStart,
                        with: data.utmData
                    )
                }
            }
        }
    }

    // MARK: Flushing

    /// This method can be used to manually flush all available data to Exponea.
    public func flushData() {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient("token, basic")
            }
            dependencies.flushingManager.flushData()
        }
    }

    // MARK: Anonymize

    /// Anonymizes the user and re-creates the database.
    /// All customer identification (inclduing cookie) will be permanently deleted.
    public func anonymize() {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient("token, basic")
            }

            try dependencies.trackingManager.anonymize()
        }
    }
}
