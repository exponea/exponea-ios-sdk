//
//  EventFilterAttributeSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 06/02/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import XCTest
import Quick
import Nimble

@testable import ExponeaSDK

final class EventFilterAttributeSpec: QuickSpec {
    override func spec() {
        describe("PropertyAttribute") {
            let event = EventFilterEvent(
                eventType: "session_start",
                properties: ["nil": nil, "value": "value"],
                timestamp: nil
            )
            it("should return isSet") {
                expect(PropertyAttribute("missing").isSet(in: event)).to(beFalse())
                expect(PropertyAttribute("nil").isSet(in: event)).to(beTrue())
                expect(PropertyAttribute("value").isSet(in: event)).to(beTrue())
            }
            it("should return getValue") {
                expect(PropertyAttribute("missing").getValue(in: event)).to(beNil())
                expect(PropertyAttribute("nil").getValue(in: event)).to(beNil())
                expect(PropertyAttribute("value").getValue(in: event)).to(equal("value"))
            }

            // swiftlint:disable open_brace_spacing close_brace_spacing
            let serialized = """
            {"type":"property","property":"value"}
            """
            // swiftlint:enable open_brace_spacing close_brace_spacing
            it("should serialize") {
                let encoded = try! JSONEncoder().encode(EventFilterAttributeCoder(PropertyAttribute("value")))
                expect(String(data: encoded, encoding: .utf8)).to(equal(serialized))
            }
            it("should deserialize") {
                let data = serialized.data(using: .utf8)!
                let decoded = try! JSONDecoder().decode(EventFilterAttributeCoder.self, from: data)
                expect(decoded).to(equal(EventFilterAttributeCoder(PropertyAttribute("value"))))
            }
        }

        describe("TimestampAttribute") {
            let eventWithoutTimestamp = EventFilterEvent(eventType: "session_start", properties: [:], timestamp: nil)
            let eventWithTimestamp = EventFilterEvent(eventType: "session_start", properties: [:], timestamp: 1234)
            it("should return isSet") {
                expect(TimestampAttribute().isSet(in: eventWithoutTimestamp)).to(beFalse())
                expect(TimestampAttribute().isSet(in: eventWithTimestamp)).to(beTrue())
            }
            it("should return getValue") {
                expect(TimestampAttribute().getValue(in: eventWithoutTimestamp)).to(beNil())
                expect(TimestampAttribute().getValue(in: eventWithTimestamp)).to(equal("1234.0"))
            }

            // swiftlint:disable open_brace_spacing close_brace_spacing
            let serialized = """
            {"type":"timestamp"}
            """
            // swiftlint:enable open_brace_spacing close_brace_spacing
            it("should serialize") {
                let encoded = try! JSONEncoder().encode(EventFilterAttributeCoder(TimestampAttribute()))
                expect(String(data: encoded, encoding: .utf8)).to(equal(serialized))
            }
            it("should deserialize") {
                let data = serialized.data(using: .utf8)!
                let decoded = try! JSONDecoder().decode(EventFilterAttributeCoder.self, from: data)
                expect(decoded).to(equal(EventFilterAttributeCoder(TimestampAttribute())))
            }
        }
    }
}
