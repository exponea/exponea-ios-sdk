//
//  GenericOperatorsSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 06/02/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import XCTest
import Quick
import Nimble

@testable import ExponeaSDK

final class GenericOperatorsSpec: QuickSpec {
    override func spec() {
        let testEvent = EventFilterEvent(
            eventType: "test",
            properties: ["string": "something", "number": 1234, "true": true, "false": false, "nil": nil],
            timestamp: 12345.0
        )

        describe("is set operator") {
            it("should pass for existing prop") {
                expect(
                    IsSetOperator.passes(event: testEvent, attribute: PropertyAttribute("string"), operands: [])
                ).to(beTrue())
            }
            it("should fail for non-existing prop") {
                expect(
                    IsSetOperator.passes(event: testEvent, attribute: PropertyAttribute("missing"), operands: [])
                ).to(beFalse())
            }
        }

        describe("is not set operator") {
            it("should fail for existing prop") {
                expect(
                    IsNotSetOperator.passes(event: testEvent, attribute: PropertyAttribute("string"), operands: [])
                ).to(beFalse())
            }
            it("should pass for non-existing prop") {
                expect(
                    IsNotSetOperator.passes(event: testEvent, attribute: PropertyAttribute("missing"), operands: [])
                ).to(beTrue())
            }
        }

        describe("has value operator") {
            it("should pass for prop with value") {
                expect(
                    HasValueOperator.passes(event: testEvent, attribute: PropertyAttribute("string"), operands: [])
                ).to(beTrue())
            }
            it("should fail for non-existing prop") {
                expect(
                    HasValueOperator.passes(event: testEvent, attribute: PropertyAttribute("missing"), operands: [])
                ).to(beFalse())
            }
            it("should fail for prop with nil value") {
                expect(
                    HasValueOperator.passes(event: testEvent, attribute: PropertyAttribute("nil"), operands: [])
                ).to(beFalse())
            }
        }

        describe("has no value operator") {
            it("should fail for prop with value") {
                expect(
                    HasNoValueOperator.passes(event: testEvent, attribute: PropertyAttribute("string"), operands: [])
                ).to(beFalse())
            }
            it("should fail for non-existing prop") {
                expect(
                    HasNoValueOperator.passes(event: testEvent, attribute: PropertyAttribute("missing"), operands: [])
                ).to(beFalse())
            }
            it("should pass for prop with nil value") {
                expect(
                    HasNoValueOperator.passes(event: testEvent, attribute: PropertyAttribute("nil"), operands: [])
                ).to(beTrue())
            }
        }
    }
}
