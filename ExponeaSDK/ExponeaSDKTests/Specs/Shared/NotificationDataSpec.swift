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
                expectedNotificationData: NotificationData(eventType: "some event type"),
                expectedProperties: ["platform": .string("ios")]
            ),
            TestCase(
                name: "and ignore incorrect data types",
                attributes: ["event_type": 12345, "actionId": "some action id", "timestamp": "invalid"],
                campaignData: [:],
                expectedNotificationData: NotificationData(),
                expectedProperties: ["platform": .string("ios")]
            ),
            TestCase(
                name: "with few properties",
                attributes: ["event_type": "some event type", "actionId": 123, "platform": "ios", "language": "en"],
                campaignData: ["utm_source": "some source"],
                expectedNotificationData: NotificationData(
                    eventType: "some event type",
                    actionId: 123,
                    platform: "ios",
                    language: "en",
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
                    eventType: "mock event type",
                    campaignId: "mock campaign id",
                    campaignName: "mock campaign name",
                    actionId: 1234,
                    actionName: "mock action name",
                    actionType: "mock action type",
                    campaignPolicy: "mock campaign policy",
                    platform: "mock platform",
                    language: "mock language",
                    recipient: "mock recipient",
                    subject: "mock title",
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
            expect(actual.eventType).to(expected.eventType == nil ? beNil() : equal(expected.eventType))
            expect(actual.campaignId).to(expected.campaignId == nil ? beNil() : equal(expected.campaignId))
            expect(actual.campaignName).to(expected.campaignName == nil ? beNil() : equal(expected.campaignName))
            expect(actual.actionId).to(expected.actionId == nil ? beNil() : equal(expected.actionId))
            expect(actual.actionName).to(expected.actionName == nil ? beNil() : equal(expected.actionName))
            expect(actual.actionType).to(expected.actionType == nil ? beNil() : equal(expected.actionType))
            expect(actual.campaignPolicy).to(expected.campaignPolicy == nil ? beNil() : equal(expected.campaignPolicy))
            expect(actual.platform).to(expected.platform == nil ? beNil() : equal(expected.platform))
            expect(actual.language).to(expected.language == nil ? beNil() : equal(expected.language))
            expect(actual.recipient).to(expected.recipient == nil ? beNil() : equal(expected.recipient))
            expect(actual.subject).to(expected.subject == nil ? beNil() : equal(expected.subject))
            expect(actual.campaignData).to(equal(expected.campaignData))
        }
    }
}
