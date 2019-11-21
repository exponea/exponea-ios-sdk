//
//  PushNotificationManagerSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 31/10/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Nimble
import Quick

@testable import ExponeaSDK
@testable import ExponeaSDKNotifications

final class PushNotificationManagerSpec: QuickSpec {
    struct TrackDeliveredTestCase {
        let name: String
        let userInfo: [String: Any]
        let expectedTrackedEvent: (Date) -> MockTrackingManager.TrackedEvent
    }

    override func spec() {
        var trackingManager: MockTrackingManager!
        var pushManager: PushNotificationManager!

        beforeEach {
            UserDefaults.standard.removePersistentDomain(forName: "mock-app-group")
            trackingManager = MockTrackingManager()
            pushManager = PushNotificationManager(
                trackingManager: trackingManager,
                appGroup: "mock-app-group",
                tokenTrackFrequency:
                TokenTrackFrequency.daily,
                currentPushToken: "mock-push-token",
                lastTokenTrackDate: Date()
            )
        }

        describe("tracking stored delivered push notifications") {
            func getFirstStoredNotification() -> ExponeaSDK.NotificationData? {
                let userDefaults = UserDefaults(suiteName: "mock-app-group")!
                let data = userDefaults.array(forKey: ExponeaSDK.Constants.General.deliveredPushUserDefaultsKey) as? [Data]
                guard let delivered = data, !delivered.isEmpty else {
                    return nil
                }
                return NotificationData.deserialize(from: delivered[0])!
            }

            it("should do nothing with no stored notification") {
                pushManager.checkForDeliveredPushMessages()
                expect(trackingManager.trackedEvents).to(beEmpty())
            }

            let testCases = [
                TrackDeliveredTestCase(
                    name: "without attributes",
                    userInfo: ["some key": "some value"],
                    expectedTrackedEvent: {
                        MockTrackingManager.TrackedEvent(
                            type: .pushDelivered,
                            data: [
                                .properties(["status": .string("delivered"), "platform": .string("ios")]),
                                .timestamp($0.timeIntervalSince1970)
                            ]
                        )
                    }
                ),
                TrackDeliveredTestCase(
                    name: "with empty attributes",
                    userInfo: ["attributes": []],
                    expectedTrackedEvent: {
                        MockTrackingManager.TrackedEvent(
                            type: .pushDelivered,
                            data: [
                                .properties(["status": .string("delivered"), "platform": .string("ios")]),
                                .timestamp($0.timeIntervalSince1970)
                            ]
                        )
                    }
                ),
                TrackDeliveredTestCase(
                    name: "with few attributes",
                    userInfo: ["attributes": [
                        "campaign_id": "mock campaign id",
                        "platform": "mock platform",
                        "action_id": 123
                    ]],
                    expectedTrackedEvent: {
                        MockTrackingManager.TrackedEvent(
                            type: .pushDelivered,
                            data: [
                                .properties([
                                    "status": .string("delivered"),
                                    "campaign_id": .string("mock campaign id"),
                                    "platform": .string("mock platform"),
                                    "action_id": .int(123)
                                ]),
                                .timestamp($0.timeIntervalSince1970)
                            ]
                        )
                    }
                ),
                TrackDeliveredTestCase(
                    name: "with custom event type",
                    userInfo: ["attributes": ["event_type": "custom push delivered"]],
                    expectedTrackedEvent: {
                        MockTrackingManager.TrackedEvent(
                            type: .customEvent,
                            data: [
                                .eventType("custom push delivered"),
                                .properties(["status": .string("delivered"), "platform": .string("ios")]),
                                .timestamp($0.timeIntervalSince1970)
                            ]
                        )
                    }
                ),
                TrackDeliveredTestCase(
                    name: "with production data",
                    userInfo: ["attributes": [
                        "subject": "Notification title",
                        "action_name": "Unnamed mobile push",
                        "event_type": "campaign",
                        "action_id": 2,
                        "platform": "ios",
                        "some property": "some value",
                        "language": "",
                        "recipient": "051AADC3AFC4B4B2AB8492ED6A152BBE485D29F9FC2A59E34C68EC5853F47A47",
                        "campaign_policy": "",
                        "campaign_id": "5db9ab54b073dfb424ccfa6f",
                        "action_type": "mobile notification",
                        "campaign_name": "Wassil's push"
                    ]],
                    expectedTrackedEvent: {
                        MockTrackingManager.TrackedEvent(
                            type: .pushDelivered,
                            data: [
                                .properties([
                                    "status": .string("delivered"),
                                    "subject": .string("Notification title"),
                                    "action_name": .string("Unnamed mobile push"),
                                    "action_id": .int(2),
                                    "platform": .string("ios"),
                                    "recipient": .string("051AADC3AFC4B4B2AB8492ED6A152BBE485D29F9FC2A59E34C68EC5853F47A47"),
                                    "campaign_id": .string("5db9ab54b073dfb424ccfa6f"),
                                    "action_type": .string("mobile notification"),
                                    "campaign_name": .string("Wassil's push"),
                                    "language": .string(""),
                                    "campaign_policy": .string("")
                                ]),
                                .timestamp($0.timeIntervalSince1970)
                            ]
                        )
                    }
                )
            ]
            testCases.forEach { testCase in
                it("should track notification with \(testCase.name)") {
                    let service = ExponeaNotificationService(appGroup: "mock-app-group")
                    service.saveNotificationForLaterTracking(userInfo: testCase.userInfo)
                    let storedNotification = getFirstStoredNotification()!
                    pushManager.checkForDeliveredPushMessages()
                    expect(trackingManager.trackedEvents.count).to(equal(1))
                    expect(trackingManager.trackedEvents[0]).to(equal(
                        testCase.expectedTrackedEvent(storedNotification.timestamp)
                    ))
                    expect(getFirstStoredNotification()).to(beNil())
                }
            }
        }
    }
}
