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

    struct NotificationOpenedTestCase {
        let name: String
        let userInfoJson: String?
        let actionIdentifier: String?
        let delegate: PushNotificationManagerDelegate? // swiftlint:disable:this weak_delegate
        let expectedTrackedEvent: MockTrackingManager.TrackedEvent?
        let expectedBrowserLinkOpened: URL?
        let expectedDeeplinkOpened: URL?
    }

    private class VerifingPushNotificationManagerDelegate: PushNotificationManagerDelegate {
        private let action: ExponeaSDK.ExponeaNotificationActionType
        private let value: String?
        private let extraData: [AnyHashable: Any]?
        init(
            action: ExponeaSDK.ExponeaNotificationActionType,
            value: String?,
            extraData: [AnyHashable: Any]?
        ) {
            self.action = action
            self.value = value
            self.extraData = extraData
        }

        func pushNotificationOpened(
            with action: ExponeaSDK.ExponeaNotificationActionType,
            value: String?,
            extraData: [AnyHashable: Any]?
        ) {
            expect(action).to(equal(self.action))
            if self.value != nil {
                expect(value).to(equal(self.value))
            } else {
                expect(value).to(beNil())
            }
            self.extraData?.forEach { expected in
                expect(
                    extraData?.contains(where: {
                        $0.key == expected.key && String(describing: $0.value) == String(describing: expected.value)

                    })
                ).to(beTrue())
            }
        }
    }

    override func spec() {
        var trackingManager: MockTrackingManager!
        var pushManager: PushNotificationManager!
        var urlOpener: MockUrlOpener!
        beforeEach {
            UserDefaults.standard.removePersistentDomain(forName: "mock-app-group")
            trackingManager = MockTrackingManager()
            urlOpener = MockUrlOpener()
            pushManager = PushNotificationManager(
                trackingManager: trackingManager,
                appGroup: "mock-app-group",
                tokenTrackFrequency:
                TokenTrackFrequency.daily,
                currentPushToken: "mock-push-token",
                lastTokenTrackDate: Date(),
                urlOpener: urlOpener
            )
        }

        describe("tracking stored delivered push notifications") {
            func getFirstStoredNotification() -> ExponeaSDK.NotificationData? {
                let userDefaults = UserDefaults(suiteName: "mock-app-group")!
                let data = userDefaults.array(
                    forKey: ExponeaSDK.Constants.General.deliveredPushUserDefaultsKey
                ) as? [Data]
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
                                    "recipient":
                                        .string("051AADC3AFC4B4B2AB8492ED6A152BBE485D29F9FC2A59E34C68EC5853F47A47"),
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
        describe("opening push notifications") {
            let testCases: [NotificationOpenedTestCase] = [
                NotificationOpenedTestCase(
                    name: "empty notification",
                    userInfoJson: nil,
                    actionIdentifier: nil,
                    delegate: nil,
                    expectedTrackedEvent: nil,
                    expectedBrowserLinkOpened: nil,
                    expectedDeeplinkOpened: nil
                ),
                NotificationOpenedTestCase(
                    name: "empty action",
                    userInfoJson: PushNotificationsTestData().deliveredBasicNotification,
                    actionIdentifier: nil,
                    delegate: nil,
                    expectedTrackedEvent: MockTrackingManager.TrackedEvent(
                        type: EventType.pushOpened,
                        data: [.properties([
                            "url": JSONValue.string("app"),
                            "platform": JSONValue.string("ios"),
                            "cta": JSONValue.string("notification"),
                            "status": JSONValue.string("clicked")
                        ])]
                    ),
                    expectedBrowserLinkOpened: nil,
                    expectedDeeplinkOpened: nil
                ),
                NotificationOpenedTestCase(
                    name: "delegate callback",
                    userInfoJson: PushNotificationsTestData().deliveredBasicNotification,
                    actionIdentifier: "com.apple.UNNotificationDefaultActionIdentifier",
                    delegate: VerifingPushNotificationManagerDelegate(
                        action: ExponeaSDK.ExponeaNotificationActionType.openApp,
                        value: nil,
                        extraData: nil
                    ),
                    expectedTrackedEvent: MockTrackingManager.TrackedEvent(
                        type: EventType.pushOpened,
                        data: [.properties([
                            "url": JSONValue.string("app"),
                            "platform": JSONValue.string("ios"),
                            "cta": JSONValue.string("notification"),
                            "status": JSONValue.string("clicked")
                        ])]
                    ),
                    expectedBrowserLinkOpened: nil,
                    expectedDeeplinkOpened: nil
                ),
                NotificationOpenedTestCase(
                    name: "browser notification",
                    userInfoJson: PushNotificationsTestData().deliveredBrowserNotification,
                    actionIdentifier: "com.apple.UNNotificationDefaultActionIdentifier",
                    delegate: nil,
                    expectedTrackedEvent: MockTrackingManager.TrackedEvent(
                        type: EventType.pushOpened,
                        data: [.properties([
                            "url": JSONValue.string("http://google.com"),
                            "platform": JSONValue.string("ios"),
                            "cta": JSONValue.string("notification"),
                            "status": JSONValue.string("clicked")
                        ])]
                    ),
                    expectedBrowserLinkOpened: URL(string: "http://google.com"),
                    expectedDeeplinkOpened: nil
                ),
                NotificationOpenedTestCase(
                    name: "deeplink notification",
                    userInfoJson: PushNotificationsTestData().deliveredDeeplinkNotification,
                    actionIdentifier: "com.apple.UNNotificationDefaultActionIdentifier",
                    delegate: nil,
                    expectedTrackedEvent: MockTrackingManager.TrackedEvent(
                        type: EventType.pushOpened,
                        data: [.properties([
                            "url": JSONValue.string("some_url"),
                            "platform": JSONValue.string("ios"),
                            "cta": JSONValue.string("notification"),
                            "status": JSONValue.string("clicked")
                        ])]
                    ),
                    expectedBrowserLinkOpened: nil,
                    expectedDeeplinkOpened: URL(string: "some_url")
                ),
                NotificationOpenedTestCase(
                    name: "production notification",
                    userInfoJson: PushNotificationsTestData().deliveredProductionNotification,
                    actionIdentifier: "EXPONEA_ACTION_APP_2",
                    delegate: VerifingPushNotificationManagerDelegate(
                        action: ExponeaSDK.ExponeaNotificationActionType.browser,
                        value: "http://google.com?search=something",
                        extraData: [
                            "campaign_id": "5db9ab54b073dfb424ccfa6f",
                            "action_id": 2,
                            "platform": "ios",
                            "some property": "some value",
                            "event_type": "campaign",
                            "language": "",
                            "subject": "Notification title",
                            "recipient": "051AADC3AFC4B4B2AB8492ED6A152BBE485D29F9FC2A59E34C68EC5853F47A47",
                            "campaign_policy": "",
                            "campaign_name": "Wassil's push",
                            "action_name": "Unnamed mobile push",
                            "action_type": "mobile notification"
                        ]
                    ),
                    expectedTrackedEvent: MockTrackingManager.TrackedEvent(
                        type: EventType.pushOpened,
                        data: [.properties([
                            "action_id": JSONValue.int(2),
                            "subject": JSONValue.string("Notification title"),
                            "campaign_name": JSONValue.string("Wassil\'s push"),
                            "campaign_id": JSONValue.string("5db9ab54b073dfb424ccfa6f"),
                            "campaign_policy": JSONValue.string(""),
                            "action_type": JSONValue.string("mobile notification"),
                            "platform": JSONValue.string("ios"),
                            "language": JSONValue.string(""),
                            "recipient": JSONValue.string(
                                "051AADC3AFC4B4B2AB8492ED6A152BBE485D29F9FC2A59E34C68EC5853F47A47"
                            ),
                            "status": JSONValue.string("clicked"),
                            "action_name": JSONValue.string("Unnamed mobile push"),
                            "cta": JSONValue.string("Action 3 title"),
                            "url": JSONValue.string("http://google.com?search=something")
                        ])]
                    ),
                    expectedBrowserLinkOpened: URL(string: "http://google.com?search=something"),
                    expectedDeeplinkOpened: nil
                )
            ]

            testCases.forEach { testCase in
                it("should handle push notification opening with \(testCase.name)") {
                    let userInfo = testCase.userInfoJson != nil
                    ? try! JSONSerialization.jsonObject(
                        with: testCase.userInfoJson!.data(using: .utf8)!, options: []
                    ) as AnyObject : nil
                    pushManager.delegate = testCase.delegate
                    pushManager.handlePushOpenedUnsafe(
                        userInfoObject: userInfo,
                        actionIdentifier: testCase.actionIdentifier
                    )
                    if testCase.expectedTrackedEvent != nil {
                        expect(trackingManager.trackedEvents.count).to(equal(1))
                        expect(trackingManager.trackedEvents[0]).to(equal(testCase.expectedTrackedEvent))
                    } else {
                        expect(trackingManager.trackedEvents).to(beEmpty())
                    }
                    if testCase.expectedBrowserLinkOpened != nil {
                        expect(urlOpener.openedBrowserLinks.count).to(equal(1))
                        expect(urlOpener.openedBrowserLinks[0]).to(
                            equal(testCase.expectedBrowserLinkOpened?.absoluteString)
                        )
                    } else {
                        expect(urlOpener.openedBrowserLinks).to(beEmpty())
                    }
                    if testCase.expectedDeeplinkOpened != nil {
                        expect(urlOpener.openedDeeplinks.count).to(equal(1))
                        expect(urlOpener.openedDeeplinks[0]).to(equal(testCase.expectedDeeplinkOpened?.absoluteString))
                    } else {
                        expect(urlOpener.openedDeeplinks).to(beEmpty())
                    }
                }
            }
        }
    }
}
