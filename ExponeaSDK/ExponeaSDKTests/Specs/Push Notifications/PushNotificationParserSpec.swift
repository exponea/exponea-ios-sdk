//
//  PushNotificationParserSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 23/10/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Quick
import Nimble

@testable import ExponeaSDK

class PushNotificationParserSpec: QuickSpec {
    struct TestCase {
        let name: String
        let userInfoJson: String?
        let actionIdentifier: String?
        let expected: PushNotificationParser.PushOpenedData?
    }

    override func spec() {
        let testCases = [
            TestCase(
                name: "empty notification",
                userInfoJson: nil,
                actionIdentifier: nil,
                expected: nil
            ),
            TestCase(
                name: "empty action",
                userInfoJson: PushNotificationsTestData().deliveredBasicNotification,
                actionIdentifier: nil,
                expected: PushNotificationParser.PushOpenedData(
                    actionType: .openApp,
                    actionValue: nil,
                    eventType: .pushOpened,
                    eventData: [.properties([
                        "status": .string("clicked"),
                        "platform": .string("ios"),
                        "cta": .string("notification"),
                        "url": .string("app")
                    ])],
                    extraData: nil
                )
            ),
            TestCase(
                name: "basic notification",
                userInfoJson: PushNotificationsTestData().deliveredBasicNotification,
                actionIdentifier: "com.apple.UNNotificationDefaultActionIdentifier",
                expected: PushNotificationParser.PushOpenedData(
                    actionType: .openApp,
                    actionValue: nil,
                    eventType: .pushOpened,
                    eventData: [.properties([
                        "status": .string("clicked"),
                        "platform": .string("ios"),
                        "cta": .string("notification"),
                        "url": .string("app")
                    ])],
                    extraData: nil
                )
            ),
            TestCase(
                name: "deeplink notification",
                userInfoJson: PushNotificationsTestData().deliveredDeeplinkNotification,
                actionIdentifier: "com.apple.UNNotificationDefaultActionIdentifier",
                expected: PushNotificationParser.PushOpenedData(
                    actionType: .deeplink,
                    actionValue: "some_url",
                    eventType: .pushOpened,
                    eventData: [.properties([
                        "status": .string("clicked"),
                        "platform": .string("ios"),
                        "cta": .string("notification"),
                        "url": .string("some_url")
                    ])],
                    extraData: nil
                )
            ),
            TestCase(
                name: "browser notification",
                userInfoJson: PushNotificationsTestData().deliveredBrowserNotification,
                actionIdentifier: "com.apple.UNNotificationDefaultActionIdentifier",
                expected: PushNotificationParser.PushOpenedData(
                    actionType: .browser,
                    actionValue: "http://google.com",
                    eventType: .pushOpened,
                    eventData: [.properties([
                        "status": .string("clicked"),
                        "platform": .string("ios"),
                        "cta": .string("notification"),
                        "url": .string("http://google.com")
                    ])],
                    extraData: nil
                )
            ),
            TestCase(
                name: "custom action notification when notification action is selected",
                userInfoJson: PushNotificationsTestData().deliveredCustomActionsNotification,
                actionIdentifier: "com.apple.UNNotificationDefaultActionIdentifier",
                expected: PushNotificationParser.PushOpenedData(
                    actionType: .openApp,
                    actionValue: nil,
                    eventType: .pushOpened,
                    eventData: [.properties([
                        "status": .string("clicked"),
                        "platform": .string("ios"),
                        "cta": .string("notification"),
                        "url": .string("app")
                    ])],
                    extraData: nil
                )
            ),
            TestCase(
                name: "custom action notification when first action is selected",
                userInfoJson: PushNotificationsTestData().deliveredCustomActionsNotification,
                actionIdentifier: "EXPONEA_ACTION_APP_0",
                expected: PushNotificationParser.PushOpenedData(
                    actionType: .openApp,
                    actionValue: nil,
                    eventType: .pushOpened,
                    eventData: [.properties([
                        "status": .string("clicked"),
                        "platform": .string("ios"),
                        "cta": .string("Action 1 title"),
                        "url": .string("app")
                    ])],
                    extraData: nil
                )
            ),
            TestCase(
                name: "custom action notification when second action is selected",
                userInfoJson: PushNotificationsTestData().deliveredCustomActionsNotification,
                actionIdentifier: "EXPONEA_ACTION_APP_1",
                expected: PushNotificationParser.PushOpenedData(
                    actionType: .deeplink,
                    actionValue: "app://deeplink",
                    eventType: .pushOpened,
                    eventData: [.properties([
                        "status": .string("clicked"),
                        "platform": .string("ios"),
                        "cta": .string("Action 2 title"),
                        "url": .string("app://deeplink")
                    ])],
                    extraData: nil
                )
            ),
            TestCase(
                name: "custom action notification when third action is selected",
                userInfoJson: PushNotificationsTestData().deliveredCustomActionsNotification,
                actionIdentifier: "EXPONEA_ACTION_APP_2",
                expected: PushNotificationParser.PushOpenedData(
                    actionType: .browser,
                    actionValue: "http://google.com",
                    eventType: .pushOpened,
                    eventData: [.properties([
                        "status": .string("clicked"),
                        "platform": .string("ios"),
                        "cta": .string("Action 3 title"),
                        "url": .string("http://google.com")
                    ])],
                    extraData: nil
                )
            ),
            TestCase(
                name: "extra data notification",
                userInfoJson: PushNotificationsTestData().deliveredExtraDataNotification,
                actionIdentifier: "com.apple.UNNotificationDefaultActionIdentifier",
                expected: PushNotificationParser.PushOpenedData(
                    actionType: .openApp,
                    actionValue: nil,
                    eventType: .pushOpened,
                    eventData: [.properties(
                        [
                            "status": .string("clicked"),
                            "platform": .string("ios"),
                            "cta": .string("notification"),
                            "url": .string("app"),
                            "campaign_id": .string("some campaign id"),
                            "campaign_name": .string("some campaign name"),
                            "action_id": .int(123)
                        ]
                    )],
                    extraData: [
                        "campaign_id": "some campaign id",
                        "campaign_name": "some campaign name",
                        "action_id": 123,
                        "something_else": "some other value",
                        "something": "some value"
                    ]
                )
            ),
            TestCase(
                name: "custom event type notification",
                userInfoJson: PushNotificationsTestData().deliveredCustomEventTypeNotification,
                actionIdentifier: "com.apple.UNNotificationDefaultActionIdentifier",
                expected: PushNotificationParser.PushOpenedData(
                    actionType: .openApp,
                    actionValue: nil,
                    eventType: .customEvent,
                    eventData: [
                        .eventType("custom push opened"),
                        .properties([
                            "status": .string("clicked"),
                            "platform": .string("ios"),
                            "cta": .string("notification"),
                            "url": .string("app")
                        ])
                    ],
                    extraData: [
                        "event_type": "custom push opened"
                    ]
                )
            ),
            TestCase(
                name: "production notification",
                userInfoJson: PushNotificationsTestData().deliveredProductionNotification,
                actionIdentifier: "com.apple.UNNotificationDefaultActionIdentifier",
                expected: PushNotificationParser.PushOpenedData(
                    actionType: .openApp,
                    actionValue: nil,
                    eventType: .pushOpened,
                    eventData: [
                        .properties([
                            "status": .string("clicked"),
                            "cta": .string("notification"),
                            "url": .string("app"),
                            "subject": .string("Notification title"),
                            "action_name": .string("Unnamed mobile push"),
                            "action_id": .int(2),
                            "platform": .string("ios"),
                            "recipient": .string("051AADC3AFC4B4B2AB8492ED6A152BBE485D29F9FC2A59E34C68EC5853F47A47"),
                            "campaign_id": .string("5db9ab54b073dfb424ccfa6f"),
                            "action_type": .string("mobile notification"),
                            "campaign_name": .string("Wassil's push"),
                            "language": .string(""),
                            "campaign_policy": .string(""),
                            "utm_source": .string("exponea"),
                            "utm_campaign": .string("Testing mobile push"),
                            "utm_medium": .string("mobile_push_notification")
                        ])
                    ],
                    extraData: [
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
                    ]
                )
            )
        ]
        testCases.forEach { testCase in
            it("should parse \(testCase.name)") {
                let userInfo = testCase.userInfoJson != nil
                    ? try! JSONSerialization.jsonObject(
                        with: testCase.userInfoJson!.data(using: .utf8)!, options: []
                    ) as AnyObject : nil
                let parsedData = PushNotificationParser.parsePushOpened(
                    userInfoObject: userInfo,
                    actionIdentifier: testCase.actionIdentifier
                )
                if testCase.expected == nil {
                    expect(parsedData).to(beNil())
                } else {
                    expect(parsedData).to(equal(testCase.expected))
                }
            }
        }
    }
}
