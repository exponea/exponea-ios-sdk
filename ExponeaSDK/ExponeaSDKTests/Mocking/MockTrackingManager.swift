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

    var customerCookie: String = "mock-cookie"

    var customerIds: [String: String] = [:]

    var customerPushToken: String?

    lazy var notificationsManager: PushNotificationManagerType = PushNotificationManager(
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

    func track(_ type: EventType, with data: [DataType]?) throws {
        trackedEvents.append(TrackedEvent(type: type, data: data))
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
}
