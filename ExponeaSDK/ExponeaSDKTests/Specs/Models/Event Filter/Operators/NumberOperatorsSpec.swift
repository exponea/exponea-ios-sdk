//
//  NumberOperatorsSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 06/02/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import XCTest
import Quick
import Nimble

@testable import ExponeaSDK

final class NumberOperatorsSpec: QuickSpec {
    override func spec() {
        let testEvent = EventFilterEvent(
            eventType: "test",
            properties: [
                "string": "something",
                "integer": 1234,
                "zero": 0,
                "pi": 3.14159,
                "boolean": false,
                "nil": nil
            ],
            timestamp: 12345.0
        )
        func passes(
            _ filterOperator: EventFilterOperator.Type,
            _ attribute: EventFilterAttribute,
            _ operandValues: [String]
        ) -> Bool {
            return filterOperator.passes(
                event: testEvent,
                attribute: attribute,
                operands: operandValues.map { EventFilterOperand(value: $0) })
        }

        describe("equal to operator") {
            it("should pass correctly") {
                expect(passes(EqualToOperator.self, PropertyAttribute("string"), ["0"])).to(beFalse())
                expect(passes(EqualToOperator.self, PropertyAttribute("integer"), ["0"])).to(beFalse())
                expect(passes(EqualToOperator.self, PropertyAttribute("zero"), ["0"])).to(beTrue())
                expect(passes(EqualToOperator.self, PropertyAttribute("pi"), ["0"])).to(beFalse())
                expect(passes(EqualToOperator.self, PropertyAttribute("boolean"), ["0"])).to(beFalse())
                expect(passes(EqualToOperator.self, PropertyAttribute("nil"), ["0"])).to(beFalse())
                expect(passes(EqualToOperator.self, PropertyAttribute("missing"), ["0"])).to(beFalse())
                expect(passes(EqualToOperator.self, TimestampAttribute(), ["0"])).to(beFalse())

                expect(passes(EqualToOperator.self, PropertyAttribute("integer"), ["1234"])).to(beTrue())
                expect(passes(EqualToOperator.self, PropertyAttribute("pi"), ["3.14159"])).to(beTrue())
                expect(passes(EqualToOperator.self, TimestampAttribute(), ["12345"])).to(beTrue())
            }
        }

        describe("in between operator") {
            it("should pass correctly") {
                expect(passes(InBetweenOperator.self, PropertyAttribute("string"), ["-1", "1"])).to(beFalse())
                expect(passes(InBetweenOperator.self, PropertyAttribute("integer"), ["-1", "1"])).to(beFalse())
                expect(passes(InBetweenOperator.self, PropertyAttribute("zero"), ["-1", "1"])).to(beTrue())
                expect(passes(InBetweenOperator.self, PropertyAttribute("pi"), ["-1", "1"])).to(beFalse())
                expect(passes(InBetweenOperator.self, PropertyAttribute("boolean"), ["-1", "1"])).to(beFalse())
                expect(passes(InBetweenOperator.self, PropertyAttribute("nil"), ["-1", "1"])).to(beFalse())
                expect(passes(InBetweenOperator.self, PropertyAttribute("missing"), ["-1", "1"])).to(beFalse())
                expect(passes(InBetweenOperator.self, TimestampAttribute(), ["-1", "1"])).to(beFalse())

                expect(passes(InBetweenOperator.self, PropertyAttribute("integer"), ["1234", "1234"])).to(beTrue())
                expect(passes(InBetweenOperator.self, PropertyAttribute("pi"), ["3", "3.2"])).to(beTrue())
                expect(passes(InBetweenOperator.self, TimestampAttribute(), ["12345", "12345"])).to(beTrue())
            }
        }

        describe("not between operator") {
            it("should pass correctly") {
                expect(passes(NotBetweenOperator.self, PropertyAttribute("string"), ["-1", "1"])).to(beFalse())
                expect(passes(NotBetweenOperator.self, PropertyAttribute("integer"), ["-1", "1"])).to(beTrue())
                expect(passes(NotBetweenOperator.self, PropertyAttribute("zero"), ["-1", "1"])).to(beFalse())
                expect(passes(NotBetweenOperator.self, PropertyAttribute("pi"), ["-1", "1"])).to(beTrue())
                expect(passes(NotBetweenOperator.self, PropertyAttribute("boolean"), ["-1", "1"])).to(beFalse())
                expect(passes(NotBetweenOperator.self, PropertyAttribute("nil"), ["-1", "1"])).to(beFalse())
                expect(passes(NotBetweenOperator.self, PropertyAttribute("missing"), ["-1", "1"])).to(beFalse())
                expect(passes(NotBetweenOperator.self, TimestampAttribute(), ["-1", "1"])).to(beTrue())

                expect(passes(NotBetweenOperator.self, PropertyAttribute("integer"), ["1234", "1234"])).to(beFalse())
                expect(passes(NotBetweenOperator.self, PropertyAttribute("pi"), ["3", "3.2"])).to(beFalse())
                expect(passes(NotBetweenOperator.self, TimestampAttribute(), ["12345", "12345"])).to(beFalse())
            }
        }

        describe("less than operator") {
            it("should pass correctly") {
                expect(passes(LessThanOperator.self, PropertyAttribute("string"), ["0"])).to(beFalse())
                expect(passes(LessThanOperator.self, PropertyAttribute("integer"), ["0"])).to(beFalse())
                expect(passes(LessThanOperator.self, PropertyAttribute("zero"), ["0"])).to(beFalse())
                expect(passes(LessThanOperator.self, PropertyAttribute("pi"), ["0"])).to(beFalse())
                expect(passes(LessThanOperator.self, PropertyAttribute("boolean"), ["0"])).to(beFalse())
                expect(passes(LessThanOperator.self, PropertyAttribute("nil"), ["0"])).to(beFalse())
                expect(passes(LessThanOperator.self, PropertyAttribute("missing"), ["0"])).to(beFalse())
                expect(passes(LessThanOperator.self, TimestampAttribute(), ["0"])).to(beFalse())

                expect(passes(LessThanOperator.self, PropertyAttribute("integer"), ["1233"])).to(beFalse())
                expect(passes(LessThanOperator.self, PropertyAttribute("pi"), ["3.1415"])).to(beFalse())
                expect(passes(LessThanOperator.self, PropertyAttribute("pi"), ["3.1416"])).to(beTrue())
                expect(passes(LessThanOperator.self, TimestampAttribute(), ["12345.1"])).to(beTrue())
            }
        }

        describe("greater than operator") {
            it("should pass correctly") {
                expect(passes(GreaterThanOperator.self, PropertyAttribute("string"), ["0"])).to(beFalse())
                expect(passes(GreaterThanOperator.self, PropertyAttribute("integer"), ["0"])).to(beTrue())
                expect(passes(GreaterThanOperator.self, PropertyAttribute("zero"), ["0"])).to(beFalse())
                expect(passes(GreaterThanOperator.self, PropertyAttribute("pi"), ["0"])).to(beTrue())
                expect(passes(GreaterThanOperator.self, PropertyAttribute("boolean"), ["0"])).to(beFalse())
                expect(passes(GreaterThanOperator.self, PropertyAttribute("nil"), ["0"])).to(beFalse())
                expect(passes(GreaterThanOperator.self, PropertyAttribute("missing"), ["0"])).to(beFalse())
                expect(passes(GreaterThanOperator.self, TimestampAttribute(), ["0"])).to(beTrue())

                expect(passes(GreaterThanOperator.self, PropertyAttribute("integer"), ["1233"])).to(beTrue())
                expect(passes(GreaterThanOperator.self, PropertyAttribute("pi"), ["3.1415"])).to(beTrue())
                expect(passes(GreaterThanOperator.self, PropertyAttribute("pi"), ["3.1416"])).to(beFalse())
                expect(passes(GreaterThanOperator.self, TimestampAttribute(), ["12344.9"])).to(beTrue())
            }
        }
    }
}
