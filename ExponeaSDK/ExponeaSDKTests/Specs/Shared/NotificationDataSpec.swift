//
//  NotificationDataSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 31/10/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Quick
import Nimble

@testable import ExponeaSDK

class NotificationDataSpec: QuickSpec {
    struct TestCase {
        let name: String
        let attributes: [String: Any]
        let campaignData: [String: Any]
        let expectedNotificationData: NotificationData
        let expectedProperties: [String: JSONValue]
    }

    override func spec() {

        let testCases = [
            TestCase(
                name: "empty data",
                attributes: [:],
                campaignData: [:],
                expectedNotificationData: NotificationData(),
                expectedProperties: ["platform": .string("ios")]
            ),
            TestCase(
                name: "with extra fields",
                attributes: ["event_type": "some event type", "some_field": "some value"]  as [String: Any],
                campaignData: [:],
                expectedNotificationData:
                    NotificationData(
                        attributes: [
                            "event_type": .string("some event type"),
                            "some_field": .string("some value")
                        ]
                    ),
                expectedProperties: ["platform": .string("ios"), "some_field": .string("some value")]
            ),
            TestCase(
                name: "with few properties",
                attributes: ["event_type": "some event type", "action_id": 123, "platform": "ios", "language": "en"],
                campaignData: ["utm_source": "some source"],
                expectedNotificationData: NotificationData(
                    attributes: [
                        "event_type": .string("some event type"),
                        "action_id": .int(123),
                        "platform": .string("ios"),
                        "language": .string("en")
                    ],
                    campaignData: CampaignData(source: "some source")
                ),
                expectedProperties: [
                    "action_id": .int(123),
                    "platform": .string("ios"),
                    "language": .string("en"),
                    "utm_source": .string("some source")
                ]
            ),
            TestCase(
                name: "with all properties",
                attributes: [
                    "event_type": "mock event type",
                    "campaign_id": "mock campaign id",
                    "campaign_name": "mock campaign name",
                    "action_id": 1234,
                    "action_name": "mock action name",
                    "action_type": "mock action type",
                    "campaign_policy": "mock campaign policy",
                    "platform": "mock platform",
                    "language": "mock language",
                    "recipient": "mock recipient",
                    "subject": "mock title"
                ],
                campaignData: [
                    "utm_source": "mock source",
                    "utm_campaign": "mock campaign",
                    "utm_content": "mock content",
                    "utm_medium": "mock medium",
                    "utm_term": "mock term",
                    "xnpe_cmp": "mock whatever this is"
                ],
                expectedNotificationData: NotificationData(
                    attributes: [
                        "event_type": .string("mock event type"),
                        "campaign_id": .string("mock campaign id"),
                        "campaign_name": .string("mock campaign name"),
                        "action_id": .int(1234),
                        "action_name": .string("mock action name"),
                        "action_type": .string("mock action type"),
                        "campaign_policy": .string("mock campaign policy"),
                        "platform": .string("mock platform"),
                        "language": .string("mock language"),
                        "recipient": .string("mock recipient"),
                        "subject": .string("mock title")],
                    campaignData: CampaignData(
                        source: "mock source",
                        campaign: "mock campaign",
                        content: "mock content",
                        medium: "mock medium",
                        term: "mock term",
                        payload: "mock whatever this is"
                    )
                ),
                expectedProperties: [
                    "campaign_id": .string("mock campaign id"),
                    "campaign_name": .string("mock campaign name"),
                    "action_id": .int(1234),
                    "action_name": .string("mock action name"),
                    "action_type": .string("mock action type"),
                    "campaign_policy": .string("mock campaign policy"),
                    "platform": .string("mock platform"),
                    "language": .string("mock language"),
                    "recipient": .string("mock recipient"),
                    "subject": .string("mock title"),
                    "utm_source": .string("mock source"),
                    "utm_campaign": .string("mock campaign"),
                    "utm_content": .string("mock content"),
                    "utm_medium": .string("mock medium"),
                    "utm_term": .string("mock term"),
                    "xnpe_cmp": .string("mock whatever this is")
                ]
            ),
            TestCase(
                name: "with nested properties",
                attributes: [
                    "first_level_attribute": "some value",
                    "array_attribute": ["a", "r", "r", "a", "y"],
                    "dictionary_attribute": [
                        "second_level_attribute": "second level value",
                        "number_attribute": 43436,
                        "nested_array": [1, 2, 3],
                        "nested_dictionary": ["key1": "value1", "key2": 3524.545]
                    ]
                ],
                campaignData: [
                    "utm_source": "mock source",
                    "utm_campaign": "mock campaign",
                    "utm_content": "mock content",
                    "utm_medium": "mock medium",
                    "utm_term": "mock term",
                    "xnpe_cmp": "mock whatever this is"
                ],
                expectedNotificationData: NotificationData(
                    attributes: [
                        "first_level_attribute": .string("some value"),
                        "array_attribute": .array([.string("a"),
                                                   .string("r"),
                                                   .string("r"),
                                                   .string("a"),
                                                   .string("y")
                        ]),
                        "dictionary_attribute": .dictionary([
                            "second_level_attribute": .string("second level value"),
                            "number_attribute": .int(43436),
                            "nested_array": .array([.int(1), .int(2), .int(3)]),
                            "nested_dictionary": .dictionary(["key1": .string("value1"), "key2": .double(3524.545)])
                        ])
                    ],
                    campaignData: CampaignData(
                        source: "mock source",
                        campaign: "mock campaign",
                        content: "mock content",
                        medium: "mock medium",
                        term: "mock term",
                        payload: "mock whatever this is"
                    )
                ),
                expectedProperties: [
                    "first_level_attribute": .string("some value"),
                    "array_attribute": .array([.string("a"), .string("r"), .string("r"), .string("a"), .string("y")]),
                    "dictionary_attribute": .dictionary([
                        "second_level_attribute": .string("second level value"),
                        "number_attribute": .int(43436),
                        "nested_array": .array([.int(1), .int(2), .int(3)]),
                        "nested_dictionary": .dictionary(["key1": .string("value1"), "key2": .double(3524.545)])
                    ]),
                    "utm_source": .string("mock source"),
                    "utm_campaign": .string("mock campaign"),
                    "utm_content": .string("mock content"),
                    "utm_medium": .string("mock medium"),
                    "utm_term": .string("mock term"),
                    "xnpe_cmp": .string("mock whatever this is"),
                    "platform": .string("ios")
                ]
            )
        ]

        testCases.forEach { testCase in
            it("should deserialize \(testCase.name)") {
                let deserialized = NotificationData.deserialize(
                    attributes: testCase.attributes,
                    campaignData: testCase.campaignData
                )
                expect(deserialized).toNot(beNil())
                checkFieldsExceptTimestamp(expected: testCase.expectedNotificationData, actual: deserialized!)
            }

            it("should serialize \(testCase.name)") {
                let deserialized = NotificationData.deserialize(
                    attributes: testCase.attributes,
                    campaignData: testCase.campaignData
                )
                expect(deserialized).toNot(beNil())
                checkFieldsExceptTimestamp(expected: testCase.expectedNotificationData, actual: deserialized!)
                let serialized = deserialized?.serialize()
                expect(serialized).toNot(beNil())
                let deserializedAgain = NotificationData.deserialize(from: serialized!)
                expect(deserializedAgain).toNot(beNil())
                checkFieldsExceptTimestamp(expected: testCase.expectedNotificationData, actual: deserializedAgain!)
                expect(deserializedAgain?.timestamp).to(equal(deserialized?.timestamp))
            }

            it("should generate properties \(testCase.name)") {
                let deserialized = NotificationData.deserialize(
                    attributes: testCase.attributes,
                    campaignData: testCase.campaignData
                )
                expect(deserialized).toNot(beNil())
                expect(deserialized?.properties).to(equal(testCase.expectedProperties))
            }
        }

        func checkFieldsExceptTimestamp(expected: NotificationData, actual: NotificationData) {
            expect(actual.attributes).to(equal(expected.attributes))
            expect(actual.campaignData).to(equal(expected.campaignData))
        }
    }
}
