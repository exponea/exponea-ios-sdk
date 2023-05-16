//
//  TrackingConsentManager.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 23/09/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//

import Foundation

class TrackingConsentManager: TrackingConsentManagerType {

    private let trackingManager: TrackingManagerType

    init(
        trackingManager: TrackingManagerType
    ) {
        self.trackingManager = trackingManager
    }

    func trackDeliveredPush(data: NotificationData, mode: MODE) {
        var trackingAllowed = true
        if mode == .CONSIDER_CONSENT && !data.hasTrackingConsent {
            Exponea.logger.log(.verbose, message: "Event for delivered notification is not tracked because consent is not given")
            trackingAllowed = false
        }
        // Create payload
        var properties: [String: JSONValue] = data.properties
        properties["status"] = .string("delivered")
        if data.consentCategoryTracking != nil {
            properties["consent_category_tracking"] = .string(data.consentCategoryTracking!)
        }

        // Track the event
        do {
            if let customEventType = data.eventType,
               !customEventType.isEmpty,
               customEventType != Constants.EventTypes.pushDelivered {
                try trackingManager.processTrack(
                    .customEvent,
                    with: [
                        .eventType(customEventType),
                        .properties(properties),
                        .timestamp(data.timestamp)
                    ],
                    trackingAllowed: trackingAllowed
                )
            } else {
                try trackingManager.processTrack(
                    .pushDelivered,
                    with: [.properties(properties), .timestamp(data.timestamp)],
                    trackingAllowed: trackingAllowed
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
        var trackingAllowed = true
        if data.considerConsent && !data.hasTrackingConsent && !GdprTracking.isTrackForced(data.actionValue) {
            Exponea.logger.log(.error, message: "Event for clicked pushnotification is not tracked because consent is not given")
            trackingAllowed = false
        }
        var eventData = data.eventData
        if !eventData.properties.contains(where: { key, _ in key == "action_type"}) {
            eventData = eventData.addProperties(["action_type": "mobile notification"])
        }
        if GdprTracking.isTrackForced(data.actionValue) {
            eventData = eventData.addProperties(["tracking_forced": true])
        }
        do {
            try self.trackingManager.processTrack(data.eventType, with: eventData, trackingAllowed: trackingAllowed)
        } catch {
            Exponea.logger.log(.error, message: "Error tracking push clicked: \(error.localizedDescription)")
        }
    }

    func trackInAppMessageShown(message: InAppMessage, mode: MODE) {
        var trackingAllowed = true
        if mode == .CONSIDER_CONSENT && !message.hasTrackingConsent {
            Exponea.logger.log(.error, message: "Event for shown inAppMessage is not tracked because consent is not given")
            trackingAllowed = false
        }
        self.trackingManager.trackInAppMessageShown(message: message, trackingAllowed: trackingAllowed)
    }

    func trackInAppMessageClick(message: InAppMessage, buttonText: String?, buttonLink: String?, mode: MODE, isUserInteraction: Bool) {
        var trackingAllowed = true
        if mode == .CONSIDER_CONSENT && !message.hasTrackingConsent && !GdprTracking.isTrackForced(buttonLink) {
            Exponea.logger.log(.error, message: "Event for clicked inAppMessage is not tracked because consent is not given")
            trackingAllowed = false
        }
        self.trackingManager.trackInAppMessageClick(message: message, buttonText: buttonText, buttonLink: buttonLink, trackingAllowed: trackingAllowed, isUserInteraction: isUserInteraction)
    }

    func trackInAppMessageClose(message: InAppMessage, mode: MODE, isUserInteraction: Bool) {
        var trackingAllowed = true
        if mode == .CONSIDER_CONSENT && !message.hasTrackingConsent {
            Exponea.logger.log(.error, message: "Event for closed inAppMessage is not tracked because consent is not given")
            trackingAllowed = false
        }
        self.trackingManager.trackInAppMessageClose(message: message, trackingAllowed: trackingAllowed, isUserInteraction: isUserInteraction)
    }

    func trackInAppMessageError(message: InAppMessage, error: String, mode: MODE) {
        var trackingAllowed = true
        if mode == .CONSIDER_CONSENT && !message.hasTrackingConsent {
            Exponea.logger.log(.error, message: "Event for error inAppMessage is not tracked because consent is not given")
            trackingAllowed = false
        }
        self.trackingManager.trackInAppMessageError(message: message, error: error, trackingAllowed: trackingAllowed)
    }

    func trackAppInboxClick(message: MessageItem, buttonText: String?, buttonLink: String?, mode: MODE) {
        guard let customerId = message.customerIds["cookie"] else {
            Exponea.logger.log(.error, message: "AppInbox message has no customerId")
            return
        }
        var trackingAllowed = true
        if mode == .CONSIDER_CONSENT && !message.hasTrackingConsent && !GdprTracking.isTrackForced(buttonLink) {
            Exponea.logger.log(.error, message: "Event for clicked AppInbox is not tracked because consent is not given")
            trackingAllowed = false
        }
        var eventData = message.content?.trackingData ?? [:]
        eventData.merge([
            "action_type": .string("app inbox"),
            "status": .string("clicked"),
            "url": .string(buttonLink ?? ""),
            "cta": .string(buttonText ?? ""),
            "platform": .string("ios")
        ]) { _, new in new }
        if GdprTracking.isTrackForced(buttonLink) {
            eventData.merge(["tracking_forced": .bool(true)]) { _, new in new }
        }
        do {
            try self.trackingManager.processTrack(
                .appInbox,
                with: [
                    .properties(eventData),
                    .timestamp(Date().timeIntervalSince1970)
                ],
                trackingAllowed: trackingAllowed,
                for: customerId
            )
        } catch {
            Exponea.logger.log(.error, message: "Error tracking AppInbox clicked: \(error.localizedDescription)")
        }
    }

    func trackAppInboxOpened(message: MessageItem, mode: MODE) {
        guard let customerId = message.customerIds["cookie"] else {
            Exponea.logger.log(.error, message: "AppInbox message contains no customerId")
            return
        }
        var trackingAllowed = true
        if mode == .CONSIDER_CONSENT && !message.hasTrackingConsent {
            Exponea.logger.log(.error, message: "Event for opened AppInbox is not tracked because consent is not given")
            trackingAllowed = false
        }
        var eventData = message.content?.trackingData ?? [:]
        eventData.merge([
            "action_type": .string("app inbox"),
            "status": .string("opened"),
            "platform": .string("ios")
        ]) { _, new in new }
        do {
            try self.trackingManager.processTrack(
                .appInbox,
                with: [
                    .properties(eventData),
                    .timestamp(Date().timeIntervalSince1970)
                ],
                trackingAllowed: trackingAllowed,
                for: customerId
            )
        } catch {
            Exponea.logger.log(.error, message: "Error tracking AppInbox opened: \(error.localizedDescription)")
        }
    }
}
