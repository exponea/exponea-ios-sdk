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

    var customerIds: [String: JSONValue] = [:]

    var customerPushToken: String?

    var notificationsManager: PushNotificationManagerType?

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

    func triggerSessionStart() throws {
        fatalError("Not implemented")
    }

    func triggerSessionEnd() throws {
        fatalError("Not implemented")
    }

    func flushData() {
        fatalError("Not implemented")
    }

    func flushData(completion: (() -> Void)?) {
        fatalError("Not implemented")
    }

    func anonymize() throws {
        fatalError("Not implemented")
    }
}
