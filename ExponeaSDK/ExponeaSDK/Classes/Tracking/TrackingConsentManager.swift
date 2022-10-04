//
//  TrackingConsentManager.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 23/09/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//

import Foundation

class TrackingConsentManager : TrackingConsentManagerType {

    private let trackingManager: TrackingManagerType

    init(
        trackingManager: TrackingManagerType
    ) {
        self.trackingManager = trackingManager
    }

    func trackDeliveredPush(data: NotificationData) {
        if (data.considerConsent && !data.hasTrackingConsent) {
            Exponea.logger.log(.verbose, message: "Event for delivered notification is not tracked because consent is not given")
            return
        }

        // Create payload
        var properties: [String: JSONValue] = data.properties
        properties["status"] = .string("delivered")
        if (data.consentCategoryTracking != nil) {
            properties["consent_category_tracking"] = .string(data.consentCategoryTracking!)
        }

        // Track the event
        do {
            if let customEventType = data.eventType,
               !customEventType.isEmpty,
               customEventType != Constants.EventTypes.pushDelivered {
                try trackingManager.track(
                    .customEvent,
                    with: [
                        .eventType(customEventType),
                        .properties(properties),
                        .timestamp(data.timestamp)
                    ]
                )
            } else {
                try trackingManager.track(
                    .pushDelivered,
                    with: [.properties(properties), .timestamp(data.timestamp)]
                )
            }
        } catch {
            Exponea.logger.log(.error, message: "Error tracking push opened: \(error.localizedDescription)")
        }
    }

    func trackClickedPush(data: AnyObject?, mode: MODE) {
        let pushOpenedData = PushNotificationParser.parsePushOpened(
            userInfoObject: data,
            actionIdentifier: nil,
            timestamp: Date().timeIntervalSince1970,
            considerConsent: mode == .CONSIDER_CONSENT
        )
        guard let pushOpenedData = pushOpenedData else {
            Exponea.logger.log(.error, message: "Event for clicked pushnotification is not tracked because payload is invalid")
            return
        }
        trackClickedPush(data: pushOpenedData)
    }

    func trackClickedPush(data: PushOpenedData) {
        if (data.considerConsent && !data.hasTrackingConsent && !GdprTracking.isTrackForced(data.actionValue)) {
            Exponea.logger.log(.error, message: "Event for clicked pushnotification is not tracked because consent is not given")
            return
        }
        var eventData = data.eventData
        if (!eventData.properties.contains(where: { key, _ in key == "action_type"})) {
            eventData = eventData.addProperties(["action_type": "mobile notification"])
        }
        if (GdprTracking.isTrackForced(data.actionValue)) {
            eventData = eventData.addProperties(["tracking_forced": true])
        }
        do {
            try self.trackingManager.track(data.eventType, with: eventData)
        } catch {
            Exponea.logger.log(.error, message: "Error tracking push clicked: \(error.localizedDescription)")
        }
    }

    func trackInAppMessageShown(message: InAppMessage, mode: MODE) {
        if (mode == .CONSIDER_CONSENT && !message.hasTrackingConsent) {
            Exponea.logger.log(.error, message: "Event for shown inAppMessage is not tracked because consent is not given")
            return
        }
        self.trackingManager.trackInAppMessageShown(message: message)
    }

    func trackInAppMessageClick(message: InAppMessage, buttonText: String?, buttonLink: String?, mode: MODE) {
        if (mode == .CONSIDER_CONSENT && !message.hasTrackingConsent && !GdprTracking.isTrackForced(buttonLink)) {
            Exponea.logger.log(.error, message: "Event for clicked inAppMessage is not tracked because consent is not given")
            return
        }
        self.trackingManager.trackInAppMessageClick(message: message, buttonText: buttonText, buttonLink: buttonLink)
    }

    func trackInAppMessageClose(message: InAppMessage, mode: MODE) {
        if (mode == .CONSIDER_CONSENT && !message.hasTrackingConsent) {
            Exponea.logger.log(.error, message: "Event for closed inAppMessage is not tracked because consent is not given")
            return
        }
        self.trackingManager.trackInAppMessageClose(message: message)
    }

    func trackInAppMessageError(message: InAppMessage, error: String, mode: MODE) {
        if (mode == .CONSIDER_CONSENT && !message.hasTrackingConsent) {
            Exponea.logger.log(.error, message: "Event for error inAppMessage is not tracked because consent is not given")
            return
        }
        self.trackingManager.trackInAppMessageError(message: message, error: error)
    }
}
