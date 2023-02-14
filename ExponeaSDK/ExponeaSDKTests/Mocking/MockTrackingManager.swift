//
//  MockTrackingManager.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 31/10/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation
@testable import ExponeaSDK

internal class MockTrackingManager: TrackingManagerType {

    public struct TrackedEvent: Equatable {
        let type: EventType
        let data: [DataType]?
    }
    public private(set) var trackedEvents: [TrackedEvent] = []

    struct CallData: Equatable {
        let event: InAppMessageEvent
        let message: InAppMessage
    }
    public var trackedInappEvents: [CallData] = []

    var customerCookie: String = "mock-cookie"

    var customerIds: [String: String] = [:]

    var customerPushToken: String?

    lazy var notificationsManager: PushNotificationManagerType = PushNotificationManager(
        trackingConsentManager: Exponea.shared.trackingConsentManager!,
        trackingManager: self,
        swizzlingEnabled: false,
        requirePushAuthorization: true,
        appGroup: "mock-app-group",
        tokenTrackFrequency: .onTokenChange,
        currentPushToken: nil,
        lastTokenTrackDate: Date(),
        urlOpener: MockUrlOpener()
    )

    var hasActiveSession: Bool = false

    var flushingMode: FlushingMode = .manual

    let onEventCallback: (EventType, [DataType]) -> Void

    init(
        onEventCallback: @escaping (EventType, [DataType]) -> Void
    ) {
        self.onEventCallback = onEventCallback
    }

    func track(_ type: EventType, with data: [DataType]?) throws {
        var payload: [DataType] = data ?? []
        if let stringEventType = getEventTypeString(type: type) {
            payload.append(.eventType(stringEventType))
        }
        trackedEvents.append(TrackedEvent(type: type, data: payload))
        onEventCallback(type, payload)
    }

    func processTrack(_ type: EventType, with data: [DataType]?, trackingAllowed: Bool) throws {
        try processTrack(type, with: data, trackingAllowed: trackingAllowed, for: nil)
    }
    
    func processTrack(
        _ type: ExponeaSDK.EventType,
        with data: [ExponeaSDK.DataType]?,
        trackingAllowed: Bool,
        for customerId: String?
    ) throws {
        var payload: [DataType] = data ?? []
        if let stringEventType = getEventTypeString(type: type) {
            payload.append(.eventType(stringEventType))
        }
        if trackingAllowed {
            trackedEvents.append(TrackedEvent(type: type, data: payload))
        }
        onEventCallback(type, payload)
    }

    func updateLastPendingEvent(ofType type: String, with data: DataType) throws {
        fatalError("Not implemented")
    }

    func hasPendingEvent(ofType type: String, withMaxAge age: Double) throws -> Bool {
        fatalError("Not implemented")
    }

    func flushData() {
        fatalError("Not implemented")
    }

    func flushData(completion: (() -> Void)?) {
        fatalError("Not implemented")
    }

    func anonymize(exponeaProject: ExponeaProject, projectMapping: [EventType: [ExponeaProject]]?) throws {
        fatalError("Not implemented")
    }

    func ensureAutomaticSessionStarted() {
        fatalError("Not implemented")
    }

    func manualSessionStart() {
        fatalError("Not implemented")
    }

    func manualSessionEnd() {
        fatalError("Not implemented")
    }

    func setAutomaticSessionTracking(automaticSessionTracking: Exponea.AutomaticSessionTracking) {
        fatalError("Not implemented")
    }
    func trackInAppMessageClick(message: InAppMessage, buttonText: String?, buttonLink: String?, trackingAllowed: Bool) {
        track(
            .click(buttonLabel: buttonText ?? "", url: buttonLink ?? "" ),
            for: message,
            trackingAllowed: trackingAllowed
        )
    }

    func trackInAppMessageClose(message: InAppMessage, trackingAllowed: Bool) {
        self.track(.close, for: message, trackingAllowed: trackingAllowed)
    }

    func trackInAppMessageShown(message: ExponeaSDK.InAppMessage, trackingAllowed: Bool) {
        self.track(.show, for: message, trackingAllowed: trackingAllowed)
    }

    func trackInAppMessageError(message: ExponeaSDK.InAppMessage, error: String, trackingAllowed: Bool) {
        self.track(.error(message: error), for: message, trackingAllowed: trackingAllowed)
    }
    
    func track(_ event: InAppMessageEvent, for message: InAppMessage, trackingAllowed: Bool) {
        if trackingAllowed {
            trackedInappEvents.append(CallData(event: event, message: message))
        }
        do {
            var eventData: [String: JSONValue] = [
                "action": .string(event.action),
                "banner_id": .string(message.id),
                "banner_name": .string(message.name),
                "banner_type": .string(message.rawMessageType ?? "null"),
                "interaction": .bool(event.isInteraction),
                "os": .string("iOS"),
                "type": .string("in-app message"),
                "variant_id": .int(message.variantId),
                "variant_name": .string(message.variantName)
            ]
            if case .click(let text, let url) = event {
                eventData["text"] = .string(text)
                eventData["link"] = .string(url)
                if GdprTracking.isTrackForced(url) {
                    eventData["tracking_forced"] = .bool(true)
                }
            }
            if case .error(let errorMessage) = event {
                eventData["error"] = .string(errorMessage)
            }
            if message.consentCategoryTracking != nil {
                eventData["consent_category_tracking"] = .string(message.consentCategoryTracking!)
            }
            try processTrack(
                .banner,
                with: [
                    .properties(DeviceProperties().properties),
                    .properties(eventData)
                ],
                trackingAllowed: trackingAllowed
            )
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
        }
    }

    func getEventTypeString(type: EventType) -> String? {
        switch type {
        case .identifyCustomer: return nil
        case .registerPushToken: return nil
        case .customEvent: return nil
        case .install: return Constants.EventTypes.installation
        case .sessionStart: return Constants.EventTypes.sessionStart
        case .sessionEnd: return Constants.EventTypes.sessionEnd
        case .payment: return Constants.EventTypes.payment
        case .pushOpened: return Constants.EventTypes.pushOpen
        case .pushDelivered: return Constants.EventTypes.pushDelivered
        case .campaignClick: return Constants.EventTypes.campaignClick
        case .banner: return Constants.EventTypes.banner
        case .appInbox: return Constants.EventTypes.appInbox
        }
    }

    func clearCalls() {
        trackedInappEvents.removeAll()
        trackedEvents.removeAll()
    }
}
