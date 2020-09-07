//
//  DataTypeSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 12/02/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class DataTypeSpec: QuickSpec {
    override func spec() {
        describe("Array of DataType") {
            context("getting event types") {
                it("should return empty array for empty array") {
                    let data: [DataType] = []
                    expect(data.eventTypes).to(equal([]))
                }
                it("should return empty array for event without event types") {
                    let data: [DataType] = [.timestamp(nil), .customerIds([:])]
                    expect(data.eventTypes).to(equal([]))
                }
                it("should return all event types") {
                    let data: [DataType] = [
                        .timestamp(nil),
                        .eventType("event type 1"),
                        .customerIds([:]),
                        .eventType("event type 2"),
                        .properties([:]),
                        .eventType("event type 3")
                    ]
                    expect(data.eventTypes).to(equal(["event type 1", "event type 2", "event type 3"]))
                }
            }

            context("getting latest timestamp") {
                it("should return nil for empty array") {
                    let data: [DataType] = []
                    expect(data.latestTimestamp).to(beNil())
                }
                it("should return nil for event without timestamp") {
                    let data: [DataType] = [.eventType("type"), .customerIds([:]), .properties([:])]
                    expect(data.latestTimestamp).to(beNil())
                }
                it("should return nil for event with nil timestamp") {
                    let data: [DataType] = [.timestamp(nil), .eventType("type"), .customerIds([:]), .timestamp(nil)]
                    expect(data.latestTimestamp).to(beNil())
                }
                it("should latest timestamp") {
                    let data: [DataType] = [
                        .timestamp(nil),
                        .timestamp(1),
                        .eventType("type"),
                        .timestamp(5),
                        .customerIds([:]),
                        .timestamp(3)
                    ]
                    expect(data.latestTimestamp).to(equal(5))
                }
            }

            context("getting properties") {
                it("should return empty map for empty array") {
                    let data: [DataType] = []
                    expect(data.properties).to(beEmpty())
                }
                it("should merge all properties together") {
                    let data: [DataType] = [
                        .properties(["prop1": .string("prop1 value"), "prop2": .string("will we overwritten")]),
                        .properties(["prop2": .int(123), "prop3": .string("will we overwritten")]),
                        .properties(["prop3": .bool(false), "prop4": .string("prop4 value")])
                    ]
                    expect(data.properties.count).to(equal(4))
                    expect(data.properties["prop1"] as? String).to(equal("prop1 value"))
                    expect(data.properties["prop2"] as? Int).to(equal(123))
                    expect(data.properties["prop3"] as? Bool).to(equal(false))
                    expect(data.properties["prop4"] as? String).to(equal("prop4 value"))
                }
            }

            describe("serialization") {
                let testCases: [(DataType, String)] = [
                    // swiftlint:disable open_brace_spacing close_brace_spacing
                    (.customerIds(["cookie": "some cookie"]), "{\"customerIds\":{\"cookie\":\"some cookie\"}}"),
                    (.properties(["prop": .string("value")]), "{\"properties\":{\"prop\":\"value\"}}"),
                    (.timestamp(12345), "{\"timestamp\":12345}"),
                    (.timestamp(nil), "{\"timestamp\":null}"),
                    (.eventType("eventType"), "{\"eventType\":\"eventType\"}"),
                    (
                        .pushNotificationToken(token: "token", authorized: true),
                        "{\"pushNotificationToken\":{\"token\":\"token\",\"authorized\":true}}"
                    ),
                    (
                        .pushNotificationToken(token: nil, authorized: false),
                        "{\"pushNotificationToken\":{\"authorized\":false}}"
                    )
                    // swiftlint:enable open_brace_spacing close_brace_spacing
                ]
                testCases.forEach { testCase in
                    it("should serialize \(testCase.1)") {
                        let encoded = try! JSONEncoder().encode(testCase.0)
                        expect(String(data: encoded, encoding: .utf8)).to(equal(testCase.1))
                    }
                    it("should deserialize \(testCase.1)") {
                        let data = testCase.1.data(using: .utf8)!
                        expect(try! JSONDecoder().decode(DataType.self, from: data)).to(equal(testCase.0))
                    }
                }
            }
        }
    }
}
