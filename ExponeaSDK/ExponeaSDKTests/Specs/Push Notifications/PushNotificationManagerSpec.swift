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
        let expectedTrackedEvent: (Double) -> MockTrackingManager.TrackedEvent
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

    struct NotificationEventsOrderTestCase {
        let name: String
        let actionIdentifier: String?
        let sentTimestamp: Double?
        let deliveredTimestamp: Double
        let openedTimestamp: Double
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

        func createPushManager(
            requirePushAuthorization: Bool,
            currentToken: String?,
            tokenTrackFrequency: ExponeaSDK.TokenTrackFrequency,
            lastTokenTrackDate: Date = Date()
        ) {
            pushManager = PushNotificationManager(
                trackingManager: trackingManager,
                swizzlingEnabled: true,
                requirePushAuthorization: requirePushAuthorization,
                appGroup: "mock-app-group",
                tokenTrackFrequency: tokenTrackFrequency,
                currentPushToken: currentToken,
                lastTokenTrackDate: lastTokenTrackDate,
                urlOpener: urlOpener
            )
        }

        beforeEach {
            UserDefaults.standard.removePersistentDomain(forName: "mock-app-group")
            trackingManager = MockTrackingManager()
            urlOpener = MockUrlOpener()
            UNAuthorizationStatusProvider.current = MockUNAuthorizationStatusProviding(status: .authorized)
            createPushManager(
                requirePushAuthorization: true,
                currentToken: "mock-push-token",
                tokenTrackFrequency: .daily
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
                                .timestamp($0)
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
                                .timestamp($0)
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
                                .timestamp($0)
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
                                .timestamp($0)
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
                                    "some property": .string("some value"),
                                    "recipient":
                                        .string("051AADC3AFC4B4B2AB8492ED6A152BBE485D29F9FC2A59E34C68EC5853F47A47"),
                                    "campaign_id": .string("5db9ab54b073dfb424ccfa6f"),
                                    "action_type": .string("mobile notification"),
                                    "campaign_name": .string("Wassil's push"),
                                    "language": .string(""),
                                    "campaign_policy": .string("")
                                ]),
                                .timestamp($0)
                            ]
                        )
                    }
                )
            ]
            testCases.forEach { testCase in
                it("should track notification with \(testCase.name)") {
                    let service = ExponeaNotificationService(appGroup: "mock-app-group")
                    let notificationData = NotificationData.deserialize(
                        attributes: testCase.userInfo["attributes"] as? [String: Any] ?? [:],
                        campaignData: testCase.userInfo["url_params"] as? [String: Any] ?? [:]
                    ) ?? NotificationData()
                    service.saveNotificationForLaterTracking(notification: notificationData)
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
                        ]),
                        .timestamp(PushNotificationsTestData.timestamp)]
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
                        ]),
                        .timestamp(PushNotificationsTestData.timestamp)]
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
                        ]),
                        .timestamp(PushNotificationsTestData.timestamp)]
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
                        ]),
                        .timestamp(PushNotificationsTestData.timestamp)]
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
                            "some property": JSONValue.string("some value"),
                            "language": JSONValue.string(""),
                            "recipient": JSONValue.string(
                                "051AADC3AFC4B4B2AB8492ED6A152BBE485D29F9FC2A59E34C68EC5853F47A47"
                            ),
                            "status": JSONValue.string("clicked"),
                            "action_name": JSONValue.string("Unnamed mobile push"),
                            "cta": JSONValue.string("Action 3 title"),
                            "url": JSONValue.string("http://google.com?search=something"),
                            "utm_source": JSONValue.string("exponea"),
                            "utm_campaign": JSONValue.string("Testing mobile push"),
                            "utm_medium": JSONValue.string("mobile_push_notification")
                        ] as [String: ExponeaSDK.JSONValue]), // without swift fails with typechecking took too long
                        .timestamp(PushNotificationsTestData.timestamp)]
                    ),
                    expectedBrowserLinkOpened: URL(string: "http://google.com?search=something"),
                    expectedDeeplinkOpened: nil
                ),
                NotificationOpenedTestCase(
                    name: "production notification with sent_timestamp and type",
                    userInfoJson: PushNotificationsTestData().notificationWithSentTimestampAndType,
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
                            "action_type": "mobile notification",
                            "sent_timestamp": PushNotificationsTestData.timestamp,
                            "type": "push"
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
                            "some property": JSONValue.string("some value"),
                            "language": JSONValue.string(""),
                            "recipient": JSONValue.string(
                                "051AADC3AFC4B4B2AB8492ED6A152BBE485D29F9FC2A59E34C68EC5853F47A47"
                            ),
                            "status": JSONValue.string("clicked"),
                            "action_name": JSONValue.string("Unnamed mobile push"),
                            "cta": JSONValue.string("Action 3 title"),
                            "url": JSONValue.string("http://google.com?search=something"),
                            "utm_source": JSONValue.string("exponea"),
                            "utm_campaign": JSONValue.string("Testing mobile push"),
                            "utm_medium": JSONValue.string("mobile_push_notification"),
                            "sent_timestamp": JSONValue.double(PushNotificationsTestData.timestamp),
                            "type": JSONValue.string("push")
                        ] as [String: ExponeaSDK.JSONValue]), // without swift fails with typechecking took too long
                        .timestamp(PushNotificationsTestData.timestamp)]
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
                        actionIdentifier: testCase.actionIdentifier,
                        timestamp: PushNotificationsTestData.timestamp
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

        describe("tracking push token") {
            let mockTokenData = "mock_token_data".data(using: .utf8)! as AnyObject
            it("should track push token if authorized") {
                UNAuthorizationStatusProvider.current = MockUNAuthorizationStatusProviding(status: .authorized)
                pushManager.handlePushTokenRegistered(dataObject: mockTokenData)
                expect(trackingManager.trackedEvents).to(equal([
                    MockTrackingManager.TrackedEvent(
                        type: .registerPushToken,
                        data: [.pushNotificationToken(token: "6D6F636B5F746F6B656E5F64617461", authorized: true)]
                    )
                ]))
            }

            it("should not track push token if not authorized") {
                UNAuthorizationStatusProvider.current = MockUNAuthorizationStatusProviding(status: .denied)
                pushManager.handlePushTokenRegistered(dataObject: mockTokenData)
                expect(trackingManager.trackedEvents).to(beEmpty())
            }

            it("should track push token if not authorized but authorization is not required") {
                UNAuthorizationStatusProvider.current = MockUNAuthorizationStatusProviding(status: .denied)
                createPushManager(
                    requirePushAuthorization: false,
                    currentToken: "mock-token",
                    tokenTrackFrequency: .onTokenChange,
                    lastTokenTrackDate: Date(timeIntervalSince1970: Date().timeIntervalSince1970 - 60 * 60 * 24 + 10)
                )
                pushManager.handlePushTokenRegistered(dataObject: mockTokenData)
                expect(trackingManager.trackedEvents).to(equal([
                    MockTrackingManager.TrackedEvent(
                        type: .registerPushToken,
                        data: [.pushNotificationToken(token: "6D6F636B5F746F6B656E5F64617461", authorized: false)]
                    )
                ]))
            }

            it("should not track token on app foreground in 'daily' frequency within one day") {
                createPushManager(
                    requirePushAuthorization: true,
                    currentToken: "mock-token",
                    tokenTrackFrequency: .onTokenChange,
                    lastTokenTrackDate: Date(timeIntervalSince1970: Date().timeIntervalSince1970 - 60 * 60 * 24 + 10)
                )
                expect(trackingManager.trackedEvents).to(beEmpty())
            }

            it("should track token on app foreground in 'daily' frequency after one day") {
                createPushManager(
                    requirePushAuthorization: true,
                    currentToken: "mock-token",
                    tokenTrackFrequency: .daily,
                    lastTokenTrackDate: Date(timeIntervalSince1970: Date().timeIntervalSince1970 - 60 * 60 * 24 - 10)
                )
                expect(trackingManager.trackedEvents).to(equal([
                    MockTrackingManager.TrackedEvent(
                        type: .registerPushToken,
                        data: [.pushNotificationToken(token: "mock-token", authorized: true)]
                    )
                ]))
            }

            it("should track token on app foreground in 'everyLaunch' frequency") {
                createPushManager(
                    requirePushAuthorization: true,
                    currentToken: "mock-token",
                    tokenTrackFrequency: .everyLaunch,
                    lastTokenTrackDate: Date(timeIntervalSince1970: 1)
                )
                expect(trackingManager.trackedEvents).to(equal([
                    MockTrackingManager.TrackedEvent(
                        type: .registerPushToken,
                        data: [.pushNotificationToken(token: "mock-token", authorized: true)]
                    )
                ]))
            }

            it("should clear token if not authorized and authorization required") {
                UNAuthorizationStatusProvider.current = MockUNAuthorizationStatusProviding(status: .denied)
                createPushManager(
                    requirePushAuthorization: true,
                    currentToken: "mock-token",
                    tokenTrackFrequency: .daily,
                    lastTokenTrackDate: Date(timeIntervalSince1970: 1)
                )
                expect(trackingManager.trackedEvents).to(equal([
                    MockTrackingManager.TrackedEvent(
                        type: .registerPushToken,
                        data: [.pushNotificationToken(token: nil, authorized: false)]
                    )
                ]))
            }

            it("should track token if not authorized and authorization not required") {
                UNAuthorizationStatusProvider.current = MockUNAuthorizationStatusProviding(status: .denied)
                createPushManager(
                    requirePushAuthorization: false,
                    currentToken: "mock-token",
                    tokenTrackFrequency: .daily,
                    lastTokenTrackDate: Date(timeIntervalSince1970: 1)
                )
                expect(trackingManager.trackedEvents).to(equal([
                    MockTrackingManager.TrackedEvent(
                        type: .registerPushToken,
                        data: [.pushNotificationToken(token: "mock-token", authorized: false)]
                    )
                ]))
            }
        }

        describe("saving opened push for later") {
            func parseUserInfo(_ string: String) -> AnyObject {
                return try! JSONSerialization.jsonObject(
                    with: string.data(using: .utf8)!, options: []
                ) as AnyObject
            }

            it("should save opened push for later") {
                PushNotificationManager.storePushOpened(
                    userInfoObject: parseUserInfo(PushNotificationsTestData().deliveredProductionNotification),
                    actionIdentifier: "com.apple.UNNotificationDefaultActionIdentifier",
                    timestamp: PushNotificationsTestData.timestamp
                )
                PushNotificationManager.storePushOpened(
                    userInfoObject: parseUserInfo(PushNotificationsTestData().deliveredSilentNotification),
                    actionIdentifier: "com.apple.UNNotificationDefaultActionIdentifier",
                    timestamp: PushNotificationsTestData.timestamp
                )

                let optionalDataArray = UserDefaults(suiteName: ExponeaSDK.Constants.General.userDefaultsSuite)?
                    .array(forKey: ExponeaSDK.Constants.General.openedPushUserDefaultsKey) as? [Data]
                guard let dataArray = optionalDataArray else {
                    XCTFail("Unable to parse data")
                    return
                }

                expect(dataArray.count).to(equal(2))
                expect(PushOpenedData.deserialize(from: dataArray[0]))
                    .to(equal(PushNotificationsTestData().openedProductionNotificationData))
                expect(PushOpenedData.deserialize(from: dataArray[1]))
                    .to(equal(PushNotificationsTestData().openedSilentNotificationData))

                UserDefaults(suiteName: ExponeaSDK.Constants.General.userDefaultsSuite)?
                    .removeObject(forKey: ExponeaSDK.Constants.General.openedPushUserDefaultsKey)
            }

            it("should process previously saved push notifications") {
                PushNotificationManager.storePushOpened(
                    userInfoObject: parseUserInfo(PushNotificationsTestData().deliveredProductionNotification),
                    actionIdentifier: "com.apple.UNNotificationDefaultActionIdentifier",
                    timestamp: PushNotificationsTestData.timestamp
                )
                PushNotificationManager.storePushOpened(
                    userInfoObject: parseUserInfo(PushNotificationsTestData().deliveredSilentNotification),
                    actionIdentifier: "com.apple.UNNotificationDefaultActionIdentifier",
                    timestamp: PushNotificationsTestData.timestamp
                )
                createPushManager(
                    requirePushAuthorization: false,
                    currentToken: "mock-token",
                    tokenTrackFrequency: .onTokenChange,
                    lastTokenTrackDate: Date(timeIntervalSince1970: 1)
                )
                expect(
                    UserDefaults(suiteName: ExponeaSDK.Constants.General.userDefaultsSuite)?
                        .array(forKey: ExponeaSDK.Constants.General.openedPushUserDefaultsKey)
                ).to(beNil())
                expect(trackingManager.trackedEvents.count).to(equal(2))
                expect(trackingManager.trackedEvents[0].type).to(equal(ExponeaSDK.EventType.pushOpened))
                expect(trackingManager.trackedEvents[1].type).to(equal(ExponeaSDK.EventType.pushDelivered))
            }
        }

        describe("tracking push events in correct order") {
            func getDelegate() -> VerifingPushNotificationManagerDelegate {
                return VerifingPushNotificationManagerDelegate(
                    action: ExponeaSDK.ExponeaNotificationActionType.browser,
                    value: "http://google.com?search=something",
                    extraData: [
                        "campaign_id": "5db9ab54b073dfb424ccfa6f",
                        "action_id": 2,
                        "platform": "ios",
                        "some property": "some value",
                        "event_type": "campaign",
                        "subject": "Notification title",
                        "recipient": "051AADC3AFC4B4B2AB8492ED6A152BBE485D29F9FC2A59E34C68EC5853F47A47",
                        "campaign_name": "My push",
                        "action_name": "Unnamed mobile push",
                        "action_type": "mobile notification",
                        "sent_timestamp": PushNotificationsTestData.timestamp,
                        "type": "push"
                    ]
                )
            }

            func getNotificationRequest(sentTimestamp: Double?, deliveredTimestamp: Double) -> UNNotificationRequest {
                let content = UNNotificationContent().mutableCopy() as? UNMutableNotificationContent

                var userInfo = [String: Any]()
                var attributes = [String: Any]()
                var urlParams = [String: Any]()

                urlParams["utm_campaign"] = "Testing mobile push"
                urlParams["utm_medium"] = "mobile_push_notification"
                urlParams["utm_source"] = "exponea"

                attributes["subject"] = "Notification title"
                attributes["action_name"] = "Unnamed mobile push"
                attributes["event_type"] = "campaign"
                attributes["action_id"] = 2
                attributes["action_type"] = "mobile notification"
                attributes["recipient"] = "051AADC3AFC4B4B2AB8492ED6A152BBE485D29F9FC2A59E34C68EC5853F47A47"
                attributes["campaign_id"] = "5db9ab54b073dfb424ccfa6f"
                attributes["campaign_name"] = "My push"
                attributes["some property"] = "some value"
                attributes["platform"] = "ios"
                if sentTimestamp != nil {
                    attributes["sent_timestamp"] = sentTimestamp
                    attributes["type"] = "push"
                }
                attributes["timestamp"] = deliveredTimestamp
                userInfo["attributes"] = attributes
                userInfo["url_params"] = urlParams
                userInfo["source"] = "xnpe_platform"

                content?.userInfo = userInfo
                return UNNotificationRequest(identifier: "notification",
                                             content: content!,
                                             trigger: nil)
            }

            func saveConfiguration() {
                try! Configuration(
                    projectToken: "mock-project-token",
                    projectMapping: nil,
                    authorization: .token("mock-token"),
                    baseUrl: nil,
                    appGroup: "mock-app-group",
                    defaultProperties: nil
                ).saveToUserDefaults()
            }

            func saveCustomerIds() {
                guard let userDefaults = UserDefaults(suiteName: "mock-app-group"),
                    let data = try? JSONEncoder().encode(["uuid": JSONValue.string("mock-uuid")]) else {
                    return
                }
                userDefaults.set(data, forKey: Constants.General.lastKnownCustomerIds)
            }
            let testCases: [NotificationEventsOrderTestCase] = [
                NotificationEventsOrderTestCase(
                    name: "sent -> delivered -> opened",
                    actionIdentifier: "EXPONEA_ACTION_APP_2",
                    sentTimestamp: PushNotificationsTestData.timestamp,
                    deliveredTimestamp: PushNotificationsTestData.timestamp + 4,
                    openedTimestamp: PushNotificationsTestData.timestamp + 8
                ),
                NotificationEventsOrderTestCase(
                    name: "sent -> opened -> delivered",
                    actionIdentifier: "EXPONEA_ACTION_APP_2",
                    sentTimestamp: PushNotificationsTestData.timestamp,
                    deliveredTimestamp: PushNotificationsTestData.timestamp + 8,
                    openedTimestamp: PushNotificationsTestData.timestamp + 4
                ),
                NotificationEventsOrderTestCase(
                    name: "delivered -> sent -> opened",
                    actionIdentifier: "EXPONEA_ACTION_APP_2",
                    sentTimestamp: PushNotificationsTestData.timestamp + 4,
                    deliveredTimestamp: PushNotificationsTestData.timestamp,
                    openedTimestamp: PushNotificationsTestData.timestamp + 8
                ),
                NotificationEventsOrderTestCase(
                    name: "delivered -> opened -> sent",
                    actionIdentifier: "EXPONEA_ACTION_APP_2",
                    sentTimestamp: PushNotificationsTestData.timestamp + 8,
                    deliveredTimestamp: PushNotificationsTestData.timestamp,
                    openedTimestamp: PushNotificationsTestData.timestamp + 4
                ),
                NotificationEventsOrderTestCase(
                    name: "opened -> sent -> delivered",
                    actionIdentifier: "EXPONEA_ACTION_APP_2",
                    sentTimestamp: PushNotificationsTestData.timestamp + 4,
                    deliveredTimestamp: PushNotificationsTestData.timestamp + 8,
                    openedTimestamp: PushNotificationsTestData.timestamp
                ),
                NotificationEventsOrderTestCase(
                    name: "opened -> delivered -> sent",
                    actionIdentifier: "EXPONEA_ACTION_APP_2",
                    sentTimestamp: PushNotificationsTestData.timestamp + 8,
                    deliveredTimestamp: PushNotificationsTestData.timestamp + 4,
                    openedTimestamp: PushNotificationsTestData.timestamp
                ),
                NotificationEventsOrderTestCase(
                    name: "opened -> delivered when sent is missing",
                    actionIdentifier: "EXPONEA_ACTION_APP_2",
                    sentTimestamp: nil,
                    deliveredTimestamp: PushNotificationsTestData.timestamp + 4,
                    openedTimestamp: PushNotificationsTestData.timestamp
                )
                ,
                NotificationEventsOrderTestCase(
                    name: "delivered -> opened when sent is missing",
                    actionIdentifier: "EXPONEA_ACTION_APP_2",
                    sentTimestamp: nil,
                    deliveredTimestamp: PushNotificationsTestData.timestamp,
                    openedTimestamp: PushNotificationsTestData.timestamp + 4
                )
            ]

            testCases.forEach { testCase in
                it("should track push events in correct order when \(testCase.name)") {
                    saveConfiguration()
                    saveCustomerIds()

                    let request = getNotificationRequest(
                        sentTimestamp: testCase.sentTimestamp,
                        deliveredTimestamp: testCase.deliveredTimestamp)

                    let service = ExponeaNotificationService(appGroup: "mock-app-group")
                    var actualDeliveredTimestamp: Double?

                    waitUntil { done in
                        NetworkStubbing.stubNetwork(
                            forProjectToken: "mock-project-token",
                            withStatusCode: 200,
                            withDelay: 0,
                            withResponseData: nil,
                            withRequestHook: { request in
                                let payload = try! JSONSerialization.jsonObject(
                                    with: request.httpBodyStream!.readFully(),
                                    options: []
                                ) as? NSDictionary ?? NSDictionary()
                                let properties = payload["properties"] as? NSDictionary
                                let status = properties?["status"] as? String
                                expect(status).to(equal("delivered"))
                                actualDeliveredTimestamp = payload["timestamp"] as? Double
                                NetworkStubbing.unstubNetwork()
                                done()
                        })
                        service.process(request: request) { _ in
                        }
                        pushManager.delegate = getDelegate()
                        pushManager.handlePushOpenedUnsafe(
                            userInfoObject: service.bestAttemptContent?.userInfo as AnyObject,
                            actionIdentifier: testCase.actionIdentifier,
                            timestamp: testCase.openedTimestamp
                        )
                    }

                    expect(trackingManager.trackedEvents.count).to(equal(1))
                    let actualOpenedTimestamp = trackingManager.trackedEvents[0].data?.latestTimestamp

                    expect(actualDeliveredTimestamp).notTo(beNil())
                    expect(actualOpenedTimestamp).notTo(beNil())
                    if testCase.sentTimestamp != nil {
                        expect(testCase.sentTimestamp).to(beLessThan(actualDeliveredTimestamp))
                    }
                    expect(actualDeliveredTimestamp).to(beLessThan(actualOpenedTimestamp))
                }
            }
        }
    }
}
