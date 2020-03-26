//
//  BooleanOperatorsSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 06/02/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import XCTest
import Quick
import Nimble

@testable import ExponeaSDK

final class BooleanOperatorsSpec: QuickSpec {
    override func spec() {
        let testEvent = EventFilterEvent(
            eventType: "test",
            properties: ["string": "something", "number": 1234, "true": true, "false": false, "nil": nil],
            timestamp: 12345.0
        )

        let trueOperand = [EventFilterOperand(value: "true")]
        let falseOperand = [EventFilterOperand(value: "false")]

        describe("is operator") {
            it("should pass correctly") {
                expect(
                    IsOperator.passes(event: testEvent, attribute: PropertyAttribute("true"), operands: trueOperand)
                ).to(beTrue())
                expect(
                    IsOperator.passes(event: testEvent, attribute: PropertyAttribute("true"), operands: falseOperand)
                ).to(beFalse())
                expect(
                    IsOperator.passes(event: testEvent, attribute: PropertyAttribute("false"), operands: trueOperand)
                ).to(beFalse())
                expect(
                    IsOperator.passes(event: testEvent, attribute: PropertyAttribute("false"), operands: falseOperand)
                ).to(beTrue())

                expect(
                    IsOperator.passes(event: testEvent, attribute: PropertyAttribute("string"), operands: trueOperand)
                ).to(beFalse())
                expect(
                    IsOperator.passes(event: testEvent, attribute: PropertyAttribute("number"), operands: trueOperand)
                ).to(beFalse())
                expect(
                    IsOperator.passes(event: testEvent, attribute: PropertyAttribute("missing"), operands: trueOperand)
                ).to(beFalse())
            }
        }
    }
}
