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
                    Exponea.logger.log(.warning, message: """
                    You should never set cookie ID directly on a customer. Ignoring.
                    """)
                }
                ids["cookie"] = dependencies.trackingManager.customerIds["cookie"]
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
                    try dependencies.trackingManager.track(.registerPushToken, with: data)
                }
            }
        }
    }

    /// Tracks the push notification clicked event to Exponea API.
    /// Event is tracked if one or both conditions met:
    //     - parameter 'has_tracking_consent' has TRUE value
    //     - provided action url has TRUE value of query parameter 'xnpe_force_track'
    public func trackPushOpened(with userInfo: [AnyHashable: Any]) {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient
            }
            dependencies.trackingConsentManager.trackClickedPush(data: userInfo as AnyObject, mode: .CONSIDER_CONSENT)
        }
    }

    /// Tracks the push notification clicked event to Exponea API.
    /// Event is tracked even if  notification and action link have not a tracking consent.
    public func trackPushOpenedWithoutTrackingConsent(with userInfo: [AnyHashable: Any]) {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient
            }
            dependencies.trackingConsentManager.trackClickedPush(data: userInfo as AnyObject, mode: .IGNORE_CONSENT)
        }
    }

    public func trackPushReceived(content: UNNotificationContent) {
        guard let userInfo = readUserInfo(content) else {
            Exponea.logger.log(.error, message: " No user info object from notification.")
            return
        }
        trackPushReceived(userInfo: userInfo)
    }

    public func trackPushReceived(userInfo: [AnyHashable: Any]) {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient
            }
            dependencies.trackingConsentManager.trackDeliveredPush(
                data: self.readNotificationData(from: userInfo),
                mode: .CONSIDER_CONSENT
            )
        }
    }

    public func trackPushReceivedWithoutTrackingConsent(content: UNNotificationContent) {
        guard let userInfo = readUserInfo(content) else {
            Exponea.logger.log(.error, message: " No user info object from notification.")
            return
        }
        trackPushReceivedWithoutTrackingConsent(userInfo: userInfo)
    }

    public func trackPushReceivedWithoutTrackingConsent(userInfo: [AnyHashable: Any]) {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient
            }
            dependencies.trackingConsentManager.trackDeliveredPush(
                data: self.readNotificationData(from: userInfo),
                mode: .IGNORE_CONSENT
            )
        }
    }

    private func readUserInfo(_ content: UNNotificationContent) -> [AnyHashable: Any]? {
        guard let userInfo = (content.mutableCopy() as? UNMutableNotificationContent)?.userInfo else {
            Exponea.logger.log(
                .error,
                message: "Failed to prepare data for delivered push notification:" +
                    " Unable to get user info object from notification."
            )
            return nil
        }
        return userInfo
    }

    private func readNotificationData(from source: [AnyHashable: Any]) -> NotificationData {
        var notificationData = NotificationData.deserialize(
            attributes: source["attributes"] as? [String: Any] ?? [:],
            campaignData: source["url_params"] as? [String: Any] ?? [:],
            consentCategoryTracking: source["consent_category_tracking"] as? String ?? nil,
            hasTrackingConsent: GdprTracking.readTrackingConsentFlag(source["has_tracking_consent"])
        ) ?? NotificationData()

        let timestamp = notificationData.timestamp
        let sentTimestamp = notificationData.sentTimestamp ?? 0
        let deliveredTimestamp = timestamp <= sentTimestamp ? sentTimestamp + 1 : timestamp
        notificationData.timestamp = deliveredTimestamp
        return notificationData
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
        executeSafelyWithDependencies { dependencies in
            // Create initial data
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient
            }
            // url and payload is required for campaigns, but missing in notifications
            if data.isValid {
                // Do the actual tracking
                var properties = data.trackingData
                properties["platform"] = .string("ios")
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
    /// Event is tracked if one or both conditions met:
    //     - parameter 'has_tracking_consent' has TRUE value
    //     - provided action url has TRUE value of query parameter 'xnpe_force_track'
    public func handlePushNotificationOpened(userInfo: [AnyHashable: Any], actionIdentifier: String? = nil) {
        guard Exponea.isExponeaNotification(userInfo: userInfo) else {
            Exponea.logger.log(.verbose, message: "Skipping non-Exponea notification")
            return
        }
        executeSafelyWithDependencies { dependencies in
            dependencies.trackingManager.notificationsManager.handlePushOpened(
                userInfoObject: userInfo as AnyObject?,
                actionIdentifier: actionIdentifier
            )
        }
    }

    /// Handles push notification opened - user action for alert notifications, delivery into app for silent pushes.
    /// This method will parse the data, track it and perform actions if needed.
    /// Event is tracked even if Notification and button link have not a tracking consent.
    public func handlePushNotificationOpenedWithoutTrackingConsent(userInfo: [AnyHashable: Any], actionIdentifier: String? = nil) {
        guard Exponea.isExponeaNotification(userInfo: userInfo) else {
            Exponea.logger.log(.verbose, message: "Skipping non-Exponea notification")
            return
        }
        executeSafelyWithDependencies { dependencies in
            dependencies.trackingManager.notificationsManager.handlePushOpenedWithoutTrackingConsent(
                userInfoObject: userInfo as AnyObject?,
                actionIdentifier: actionIdentifier
            )
        }
    }

    /// Handles push notification token registration - compared to trackPushToken respects requirePushAuthorization
    public func handlePushNotificationToken(token: String) {
        executeSafelyWithDependencies { dependencies in
            dependencies.trackingManager.notificationsManager.handlePushTokenRegistered(token: token)
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
            self.anonymize(
                exponeaProject: dependencies.configuration.mainProject,
                projectMapping: dependencies.configuration.projectMapping
            )
        }
    }

    /// Anonymizes the user and starts tracking as if the app was just installed.
    /// All customer identification (including cookie) will be permanently deleted.
    /// Switches tracking into provided exponeaProject
    public func anonymize(
        exponeaProject: ExponeaProject,
        projectMapping: [EventType: [ExponeaProject]]?
    ) {
        executeSafelyWithDependencies { dependencies in
            try dependencies.trackingManager.anonymize(
                exponeaProject: exponeaProject,
                projectMapping: projectMapping
            )
            dependencies.inAppMessagesManager.anonymize()
            dependencies.appInboxManager.clear()
            dependencies.inAppContentBlocksManager.anonymize()
            SegmentationManager.shared.anonymize()
            self.telemetryManager?.report(eventWithType: .anonymize, properties: [:])
        }
    }

    /// Track in-app message banner click event
    /// Event is tracked if one or both conditions met:
    //     - parameter 'message' has TRUE value of 'hasTrackingConsent' property
    //     - parameter 'buttonLink' has TRUE value of query parameter 'xnpe_force_track'
    public func trackInAppMessageClick(
        message: InAppMessage,
        buttonText: String?,
        buttonLink: String?
    ) {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient
            }
            dependencies.trackingConsentManager.trackInAppMessageClick(
                message: message,
                buttonText: buttonText,
                buttonLink: buttonLink,
                mode: .CONSIDER_CONSENT,
                isUserInteraction: true
            )
        }
    }

    /// Track in-app message banner click event
    /// Event is tracked even if InAppMessage and button link have not a tracking consent.
    public func trackInAppMessageClickWithoutTrackingConsent(
        message: InAppMessage,
        buttonText: String?,
        buttonLink: String?
    ) {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient
            }
            dependencies.trackingConsentManager.trackInAppMessageClick(
                message: message,
                buttonText: buttonText,
                buttonLink: buttonLink,
                mode: .IGNORE_CONSENT,
                isUserInteraction: true
            )
        }
    }

    /// Track in-app message banner close event
    public func trackInAppMessageClose(
        message: InAppMessage,
        isUserInteraction: Bool?
    ) {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient
            }
            dependencies.trackingConsentManager.trackInAppMessageClose(message: message, mode: .CONSIDER_CONSENT, isUserInteraction: isUserInteraction == true)
        }
    }

    /// Track in-app message banner close event
    public func trackInAppMessageCloseClickWithoutTrackingConsent(
        message: InAppMessage,
        isUserInteraction: Bool?
    ) {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient
            }
            dependencies.trackingConsentManager.trackInAppMessageClose(message: message, mode: .IGNORE_CONSENT, isUserInteraction: isUserInteraction == true)
        }
    }

    /// Track AppInbox message detail opened event
    /// Event is tracked if parameter 'message' has TRUE value of 'hasTrackingConsent' property
    public func trackAppInboxOpened(message: MessageItem) {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient
            }
            dependencies.trackingConsentManager.trackAppInboxOpened(
                message: message,
                mode: .CONSIDER_CONSENT
            )
        }
    }

    /// Marks AppInbox message as read
    public func markAppInboxAsRead(_ message: MessageItem, completition: ((Bool) -> Void)?) {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient
            }
            dependencies.appInboxManager.markMessageAsRead(message, nil, completition)
        }
    }

    /// Track AppInbox message detail opened event
    public func trackAppInboxOpenedWithoutTrackingConsent(message: MessageItem) {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient
            }
            dependencies.trackingConsentManager.trackAppInboxOpened(
                message: message,
                mode: .IGNORE_CONSENT
            )
        }
    }

    /// Track AppInbox message click event
    /// Event is tracked if one or both conditions met:
    ///     - parameter 'message' has TRUE value of 'hasTrackingConsent' property
    ///     - parameter 'buttonLink' has TRUE value of query parameter 'xnpe_force_track'
    public func trackAppInboxClick(
        action: MessageItemAction,
        message: MessageItem
    ) {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient
            }
            dependencies.trackingConsentManager.trackAppInboxClick(
                message: message,
                buttonText: action.title,
                buttonLink: action.url,
                mode: .CONSIDER_CONSENT
            )
        }
    }

    /// Track AppInbox message click event
    public func trackAppInboxClickWithoutTrackingConsent(
        action: MessageItemAction,
        message: MessageItem
    ) {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient
            }
            dependencies.trackingConsentManager.trackAppInboxClick(
                message: message,
                buttonText: action.title,
                buttonLink: action.url,
                mode: .IGNORE_CONSENT
            )
        }
    }

    public func trackInAppContentBlockClick(
        placeholderId: String,
        action: InAppContentBlockAction,
        message: InAppContentBlockResponse
    ) {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient
            }
            dependencies.trackingConsentManager.trackInAppContentBlockClick(
                placeholderId: placeholderId,
                message: message,
                action: action,
                mode: .CONSIDER_CONSENT
            )
        }
    }

    public func trackInAppContentBlockClickWithoutTrackingConsent(
        placeholderId: String,
        action: InAppContentBlockAction,
        message: InAppContentBlockResponse
    ) {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient
            }
            dependencies.trackingConsentManager.trackInAppContentBlockClick(
                placeholderId: placeholderId,
                message: message,
                action: action,
                mode: .IGNORE_CONSENT
            )
        }
    }
 
    public func trackInAppContentBlockClose(
        placeholderId: String,
        message: InAppContentBlockResponse
    ) {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient
            }
            dependencies.trackingConsentManager.trackInAppContentBlockClose(
                placeholderId: placeholderId,
                message: message,
                mode: .CONSIDER_CONSENT
            )
        }
    }
    
    public func trackInAppContentBlockCloseWithoutTrackingConsent(
        placeholderId: String,
        message: InAppContentBlockResponse
    ) {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient
            }
            dependencies.trackingConsentManager.trackInAppContentBlockClose(
                placeholderId: placeholderId,
                message: message,
                mode: .IGNORE_CONSENT
            )
        }
    }
    
    public func trackInAppContentBlockShown(
        placeholderId: String,
        message: InAppContentBlockResponse
    ) {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient
            }
            dependencies.trackingConsentManager.trackInAppContentBlockShow(
                placeholderId: placeholderId,
                message: message,
                mode: .CONSIDER_CONSENT
            )
        }
    }
    
    public func trackInAppContentBlockShownWithoutTrackingConsent(
        placeholderId: String,
        message: InAppContentBlockResponse
    ) {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient
            }
            dependencies.trackingConsentManager.trackInAppContentBlockShow(
                placeholderId: placeholderId,
                message: message,
                mode: .IGNORE_CONSENT
            )
        }
    }
    
    public func trackInAppContentBlockError(
        placeholderId: String,
        message: InAppContentBlockResponse,
        errorMessage: String
    ) {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient
            }
            dependencies.trackingConsentManager.trackInAppContentBlockError(
                placeholderId: placeholderId,
                message: message,
                errorMessage: errorMessage,
                mode: .CONSIDER_CONSENT
            )
        }
    }
    
    public func trackInAppContentBlockErrorWithoutTrackingConsent(
        placeholderId: String,
        message: InAppContentBlockResponse,
        errorMessage: String
    ) {
        executeSafelyWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient
            }
            dependencies.trackingConsentManager.trackInAppContentBlockError(
                placeholderId: placeholderId,
                message: message,
                errorMessage: errorMessage,
                mode: .IGNORE_CONSENT
            )
        }
    }
}
