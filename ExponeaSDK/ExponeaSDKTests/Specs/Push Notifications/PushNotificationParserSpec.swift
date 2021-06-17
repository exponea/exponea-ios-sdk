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
        let expected: PushOpenedData?
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
                expected: PushOpenedData(
                    silent: false,
                    campaignData: CampaignData(),
                    actionType: .openApp,
                    actionValue: nil,
                    eventType: .pushOpened,
                    eventData: [
                        .properties([
                            "status": .string("clicked"),
                            "platform": .string("ios"),
                            "cta": .string("notification"),
                            "url": .string("app")
                        ]),
                        .timestamp(PushNotificationsTestData.timestamp)],
                    extraData: nil
                )
            ),
            TestCase(
                name: "basic notification",
                userInfoJson: PushNotificationsTestData().deliveredBasicNotification,
                actionIdentifier: "com.apple.UNNotificationDefaultActionIdentifier",
                expected: PushOpenedData(
                    silent: false,
                    campaignData: CampaignData(),
                    actionType: .openApp,
                    actionValue: nil,
                    eventType: .pushOpened,
                    eventData: [
                        .properties([
                            "status": .string("clicked"),
                            "platform": .string("ios"),
                            "cta": .string("notification"),
                            "url": .string("app")
                        ]),
                        .timestamp(PushNotificationsTestData.timestamp)],
                    extraData: nil
                )
            ),
            TestCase(
                name: "deeplink notification",
                userInfoJson: PushNotificationsTestData().deliveredDeeplinkNotification,
                actionIdentifier: "com.apple.UNNotificationDefaultActionIdentifier",
                expected: PushOpenedData(
                    silent: false,
                    campaignData: CampaignData(),
                    actionType: .deeplink,
                    actionValue: "some_url",
                    eventType: .pushOpened,
                    eventData: [
                        .properties([
                            "status": .string("clicked"),
                            "platform": .string("ios"),
                            "cta": .string("notification"),
                            "url": .string("some_url")
                        ]),
                        .timestamp(PushNotificationsTestData.timestamp)],
                    extraData: nil
                )
            ),
            TestCase(
                name: "browser notification",
                userInfoJson: PushNotificationsTestData().deliveredBrowserNotification,
                actionIdentifier: "com.apple.UNNotificationDefaultActionIdentifier",
                expected: PushOpenedData(
                    silent: false,
                    campaignData: CampaignData(),
                    actionType: .browser,
                    actionValue: "http://google.com",
                    eventType: .pushOpened,
                    eventData: [
                        .properties([
                            "status": .string("clicked"),
                            "platform": .string("ios"),
                            "cta": .string("notification"),
                            "url": .string("http://google.com")
                        ]),
                        .timestamp(PushNotificationsTestData.timestamp)],
                    extraData: nil
                )
            ),
            TestCase(
                name: "custom action notification when notification action is selected",
                userInfoJson: PushNotificationsTestData().deliveredCustomActionsNotification,
                actionIdentifier: "com.apple.UNNotificationDefaultActionIdentifier",
                expected: PushOpenedData(
                    silent: false,
                    campaignData: CampaignData(),
                    actionType: .openApp,
                    actionValue: nil,
                    eventType: .pushOpened,
                    eventData: [
                        .properties([
                            "status": .string("clicked"),
                            "platform": .string("ios"),
                            "cta": .string("notification"),
                            "url": .string("app")
                        ]),
                        .timestamp(PushNotificationsTestData.timestamp)],
                    extraData: nil
                )
            ),
            TestCase(
                name: "custom action notification when first action is selected",
                userInfoJson: PushNotificationsTestData().deliveredCustomActionsNotification,
                actionIdentifier: "EXPONEA_ACTION_APP_0",
                expected: PushOpenedData(
                    silent: false,
                    campaignData: CampaignData(),
                    actionType: .openApp,
                    actionValue: nil,
                    eventType: .pushOpened,
                    eventData: [
                        .properties([
                            "status": .string("clicked"),
                            "platform": .string("ios"),
                            "cta": .string("Action 1 title"),
                            "url": .string("app")
                        ]),
                        .timestamp(PushNotificationsTestData.timestamp)],
                    extraData: nil
                )
            ),
            TestCase(
                name: "custom action notification when second action is selected",
                userInfoJson: PushNotificationsTestData().deliveredCustomActionsNotification,
                actionIdentifier: "EXPONEA_ACTION_APP_1",
                expected: PushOpenedData(
                    silent: false,
                    campaignData: CampaignData(),
                    actionType: .deeplink,
                    actionValue: "app://deeplink",
                    eventType: .pushOpened,
                    eventData: [
                        .properties([
                            "status": .string("clicked"),
                            "platform": .string("ios"),
                            "cta": .string("Action 2 title"),
                            "url": .string("app://deeplink")
                        ]),
                        .timestamp(PushNotificationsTestData.timestamp)],
                    extraData: nil
                )
            ),
            TestCase(
                name: "custom action notification when third action is selected",
                userInfoJson: PushNotificationsTestData().deliveredCustomActionsNotification,
                actionIdentifier: "EXPONEA_ACTION_APP_2",
                expected: PushOpenedData(
                    silent: false,
                    campaignData: CampaignData(),
                    actionType: .browser,
                    actionValue: "http://google.com",
                    eventType: .pushOpened,
                    eventData: [
                        .properties([
                            "status": .string("clicked"),
                            "platform": .string("ios"),
                            "cta": .string("Action 3 title"),
                            "url": .string("http://google.com")
                        ]),
                        .timestamp(PushNotificationsTestData.timestamp)],
                    extraData: nil
                )
            ),
            TestCase(
                name: "extra data notification",
                userInfoJson: PushNotificationsTestData().deliveredExtraDataNotification,
                actionIdentifier: "com.apple.UNNotificationDefaultActionIdentifier",
                expected: PushOpenedData(
                    silent: false,
                    campaignData: CampaignData(),
                    actionType: .openApp,
                    actionValue: nil,
                    eventType: .pushOpened,
                    eventData: [
                        .properties(
                        [
                            "status": .string("clicked"),
                            "platform": .string("ios"),
                            "cta": .string("notification"),
                            "url": .string("app"),
                            "campaign_id": .string("some campaign id"),
                            "campaign_name": .string("some campaign name"),
                            "action_id": .int(123),
                            "something_else": .string("some other value"),
                            "something": .string("some value")
                        ]),
                        .timestamp(PushNotificationsTestData.timestamp)],
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
                expected: PushOpenedData(
                    silent: false,
                    campaignData: CampaignData(),
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
                        ]),
                        .timestamp(PushNotificationsTestData.timestamp)
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
                expected: PushNotificationsTestData().openedProductionNotificationData
            ),
            TestCase(
                name: "silent action",
                userInfoJson: PushNotificationsTestData().deliveredSilentNotification,
                actionIdentifier: nil,
                expected: PushNotificationsTestData().openedSilentNotificationData
            ),
            TestCase(
                name: "nested attributes notification",
                userInfoJson: PushNotificationsTestData().notificationWithNestedAttributes,
                actionIdentifier: "com.apple.UNNotificationDefaultActionIdentifier",
                expected: PushOpenedData(
                    silent: false,
                    campaignData: CampaignData(),
                    actionType: .openApp,
                    actionValue: nil,
                    eventType: .pushOpened,
                    eventData: [
                        .properties([
                            "first_level_attribute": .string("some value"),
                            "array_attribute": .array([.string("a"),
                                                       .string("r"),
                                                       .string("r"),
                                                       .string("a"),
                                                       .string("y")]),
                            "dictionary_attribute": .dictionary([
                                "second_level_attribute": .string("second level value"),
                                "number_attribute": .int(43436),
                                "nested_array": .array([.int(1), .int(2), .int(3)]),
                                "nested_dictionary": .dictionary(["key1": .string("value1"), "key2": .double(3524.545)])
                            ]),
                            "product_list": .array([
                                .dictionary([
                                "item_id": .string("1234"),
                                "item_quantity": .int(3)
                            ]), .dictionary([
                                "item_id": .string("2345"),
                                "item_quantity": .int(2)
                            ]), .dictionary([
                                "item_id": .string("6789"),
                                "item_quantity": .int(1)
                            ])]),
                            "product_ids": .array([.string("1234"), .string("2345"), .string("6789")]),
                            "push_content": .dictionary([
                                "title": .string("Hey!"),
                                "actions": .array([
                                    .dictionary([
                                        "title": .string("Action 1 title"),
                                        "action": .string("app")
                                ])]),
                                "message": .string("We have a great deal for you today, don't miss it!")
                            ]),
                            "status": .string("clicked"),
                            "platform": .string("ios"),
                            "cta": JSONValue.string("notification"),
                            "url": JSONValue.string("app")
                        ]),
                        .timestamp(PushNotificationsTestData.timestamp)],
                    extraData: [
                        "first_level_attribute": "some value",
                        "array_attribute": ["a", "r", "r", "a", "y"],
                        "dictionary_attribute": [
                            "second_level_attribute": "second level value",
                            "number_attribute": 43436,
                            "nested_array": [1, 2, 3],
                            "nested_dictionary": ["key1": "value1", "key2": 3524.545]
                        ],
                        "product_list": [[
                            "item_id": "1234",
                            "item_quantity": 3
                        ], [
                            "item_id": "2345",
                            "item_quantity": 2
                        ], [
                            "item_id": "6789",
                            "item_quantity": 1
                        ]],
                        "product_ids": ["1234", "2345", "6789"],
                        "push_content": [
                            "title": "Hey!",
                            "actions": [[
                                "title": "Action 1 title",
                                "action": "app"
                            ]],
                            "message": "We have a great deal for you today, don't miss it!"
                        ]
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
                    actionIdentifier: testCase.actionIdentifier,
                    timestamp: PushNotificationsTestData.timestamp
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
