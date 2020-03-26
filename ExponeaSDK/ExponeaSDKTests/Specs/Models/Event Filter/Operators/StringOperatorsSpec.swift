//
//  StringOperatorsSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 06/02/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import XCTest
import Quick
import Nimble

@testable import ExponeaSDK

final class StringOperatorsSpec: QuickSpec {
    override func spec() {
        let testEvent = EventFilterEvent(
            eventType: "test",
            properties: ["string": "something", "number": 1234, "true": true, "false": false, "nil": nil],
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

        describe("equals operator") {
            it("should pass correctly") {
                expect(passes(EqualsOperator.self, PropertyAttribute("string"), ["something"])).to(beTrue())
                expect(passes(EqualsOperator.self, PropertyAttribute("number"), ["something"])).to(beFalse())
                expect(passes(EqualsOperator.self, PropertyAttribute("true"), ["something"])).to(beFalse())
                expect(passes(EqualsOperator.self, PropertyAttribute("false"), ["something"])).to(beFalse())
                expect(passes(EqualsOperator.self, PropertyAttribute("nil"), ["something"])).to(beFalse())
                expect(passes(EqualsOperator.self, PropertyAttribute("missing"), ["something"])).to(beFalse())
                expect(passes(EqualsOperator.self, TimestampAttribute(), ["something"])).to(beFalse())

                expect(passes(EqualsOperator.self, PropertyAttribute("number"), ["1234"])).to(beTrue())
                expect(passes(EqualsOperator.self, PropertyAttribute("true"), ["true"])).to(beTrue())
                expect(passes(EqualsOperator.self, PropertyAttribute("false"), ["false"])).to(beTrue())
                expect(passes(EqualsOperator.self, PropertyAttribute("nil"), ["nil"])).to(beFalse())
                expect(passes(EqualsOperator.self, PropertyAttribute("missing"), ["nil"])).to(beFalse())
                expect(passes(EqualsOperator.self, TimestampAttribute(), ["12345.0"])).to(beTrue())
            }
        }

        describe("does not equal operator") {
            it("should pass correctly") {
                expect(passes(DoesNotEqualOperator.self, PropertyAttribute("string"), ["something"])).to(beFalse())
                expect(passes(DoesNotEqualOperator.self, PropertyAttribute("number"), ["something"])).to(beTrue())
                expect(passes(DoesNotEqualOperator.self, PropertyAttribute("true"), ["something"])).to(beTrue())
                expect(passes(DoesNotEqualOperator.self, PropertyAttribute("false"), ["something"])).to(beTrue())
                expect(passes(DoesNotEqualOperator.self, PropertyAttribute("nil"), ["something"])).to(beFalse())
                expect(passes(DoesNotEqualOperator.self, PropertyAttribute("missing"), ["something"])).to(beFalse())
                expect(passes(DoesNotEqualOperator.self, TimestampAttribute(), ["something"])).to(beTrue())

                expect(passes(DoesNotEqualOperator.self, PropertyAttribute("number"), ["1234"])).to(beFalse())
                expect(passes(DoesNotEqualOperator.self, PropertyAttribute("true"), ["true"])).to(beFalse())
                expect(passes(DoesNotEqualOperator.self, PropertyAttribute("false"), ["false"])).to(beFalse())
                expect(passes(DoesNotEqualOperator.self, PropertyAttribute("nil"), ["nil"])).to(beFalse())
                expect(passes(DoesNotEqualOperator.self, PropertyAttribute("missing"), ["nil"])).to(beFalse())
                expect(passes(DoesNotEqualOperator.self, TimestampAttribute(), ["12345.0"])).to(beFalse())
            }
        }

        describe("in operator") {
            it("should pass correctly") {
                expect(passes(InOperator.self, PropertyAttribute("string"), ["something", "false"])).to(beTrue())
                expect(passes(InOperator.self, PropertyAttribute("number"), ["something", "false"])).to(beFalse())
                expect(passes(InOperator.self, PropertyAttribute("true"), ["something", "false"])).to(beFalse())
                expect(passes(InOperator.self, PropertyAttribute("false"), ["something", "false"])).to(beTrue())
                expect(passes(InOperator.self, PropertyAttribute("nil"), ["something", "false"])).to(beFalse())
                expect(passes(InOperator.self, PropertyAttribute("missing"), ["something", "false"])).to(beFalse())
                expect(passes(InOperator.self, TimestampAttribute(), ["something", "false"])).to(beFalse())

                expect(passes(InOperator.self, PropertyAttribute("number"), ["1", "1234"])).to(beTrue())
                expect(passes(InOperator.self, PropertyAttribute("true"), ["true", "false"])).to(beTrue())
                expect(passes(InOperator.self, PropertyAttribute("false"), ["true", "false"])).to(beTrue())
                expect(passes(InOperator.self, PropertyAttribute("nil"), ["nil"])).to(beFalse())
                expect(passes(InOperator.self, PropertyAttribute("missing"), ["nil"])).to(beFalse())

                expect(passes(InOperator.self, TimestampAttribute(), ["12345.0"])).to(beTrue())
            }
        }

        describe("not in operator") {
            it("should pass correctly") {
                expect(passes(NotInOperator.self, PropertyAttribute("string"), ["something", "false"])).to(beFalse())
                expect(passes(NotInOperator.self, PropertyAttribute("number"), ["something", "false"])).to(beTrue())
                expect(passes(NotInOperator.self, PropertyAttribute("true"), ["something", "false"])).to(beTrue())
                expect(passes(NotInOperator.self, PropertyAttribute("false"), ["something", "false"])).to(beFalse())
                expect(passes(NotInOperator.self, PropertyAttribute("nil"), ["something", "false"])).to(beFalse())
                expect(passes(NotInOperator.self, PropertyAttribute("missing"), ["something", "false"])).to(beFalse())
                expect(passes(NotInOperator.self, TimestampAttribute(), ["something", "false"])).to(beTrue())

                expect(passes(NotInOperator.self, PropertyAttribute("number"), ["1", "1234"])).to(beFalse())
                expect(passes(NotInOperator.self, PropertyAttribute("true"), ["true", "false"])).to(beFalse())
                expect(passes(NotInOperator.self, PropertyAttribute("false"), ["true", "false"])).to(beFalse())
                expect(passes(NotInOperator.self, PropertyAttribute("nil"), ["nil"])).to(beFalse())
                expect(passes(NotInOperator.self, PropertyAttribute("missing"), ["nil"])).to(beFalse())

                expect(passes(NotInOperator.self, TimestampAttribute(), ["12345.0"])).to(beFalse())
            }
        }

        describe("contains operator") {
            it("should pass correctly") {
                expect(passes(ContainsOperator.self, PropertyAttribute("string"), ["t"])).to(beTrue())
                expect(passes(ContainsOperator.self, PropertyAttribute("number"), ["t"])).to(beFalse())
                expect(passes(ContainsOperator.self, PropertyAttribute("true"), ["t"])).to(beTrue())
                expect(passes(ContainsOperator.self, PropertyAttribute("false"), ["t"])).to(beFalse())
                expect(passes(ContainsOperator.self, PropertyAttribute("nil"), ["t"])).to(beFalse())
                expect(passes(ContainsOperator.self, PropertyAttribute("missing"), ["t"])).to(beFalse())
                expect(passes(ContainsOperator.self, TimestampAttribute(), ["t"])).to(beFalse())

                expect(passes(ContainsOperator.self, PropertyAttribute("number"), ["2"])).to(beTrue())
                expect(passes(ContainsOperator.self, PropertyAttribute("true"), ["ru"])).to(beTrue())
                expect(passes(ContainsOperator.self, PropertyAttribute("false"), ["false"])).to(beTrue())
                expect(passes(ContainsOperator.self, PropertyAttribute("nil"), ["nil"])).to(beFalse())
                expect(passes(ContainsOperator.self, PropertyAttribute("missing"), ["nil"])).to(beFalse())
                expect(passes(ContainsOperator.self, TimestampAttribute(), ["12345.0"])).to(beTrue())
            }
        }

        describe("does not contain operator") {
            it("should pass correctly") {
                expect(passes(DoesNotContainOperator.self, PropertyAttribute("string"), ["t"])).to(beFalse())
                expect(passes(DoesNotContainOperator.self, PropertyAttribute("number"), ["t"])).to(beTrue())
                expect(passes(DoesNotContainOperator.self, PropertyAttribute("true"), ["t"])).to(beFalse())
                expect(passes(DoesNotContainOperator.self, PropertyAttribute("false"), ["t"])).to(beTrue())
                expect(passes(DoesNotContainOperator.self, PropertyAttribute("nil"), ["t"])).to(beFalse())
                expect(passes(DoesNotContainOperator.self, PropertyAttribute("missing"), ["t"])).to(beFalse())
                expect(passes(DoesNotContainOperator.self, TimestampAttribute(), ["t"])).to(beTrue())

                expect(passes(DoesNotContainOperator.self, PropertyAttribute("number"), ["2"])).to(beFalse())
                expect(passes(DoesNotContainOperator.self, PropertyAttribute("true"), ["ru"])).to(beFalse())
                expect(passes(DoesNotContainOperator.self, PropertyAttribute("false"), ["false"])).to(beFalse())
                expect(passes(DoesNotContainOperator.self, PropertyAttribute("nil"), ["nil"])).to(beFalse())
                expect(passes(DoesNotContainOperator.self, PropertyAttribute("missing"), ["nil"])).to(beFalse())
                expect(passes(DoesNotContainOperator.self, TimestampAttribute(), ["12345.0"])).to(beFalse())
            }
        }

        describe("starts with operator") {
            it("should pass correctly") {
                expect(passes(StartsWithOperator.self, PropertyAttribute("string"), ["t"])).to(beFalse())
                expect(passes(StartsWithOperator.self, PropertyAttribute("number"), ["t"])).to(beFalse())
                expect(passes(StartsWithOperator.self, PropertyAttribute("true"), ["t"])).to(beTrue())
                expect(passes(StartsWithOperator.self, PropertyAttribute("false"), ["t"])).to(beFalse())
                expect(passes(StartsWithOperator.self, PropertyAttribute("nil"), ["t"])).to(beFalse())
                expect(passes(StartsWithOperator.self, PropertyAttribute("missing"), ["t"])).to(beFalse())
                expect(passes(StartsWithOperator.self, TimestampAttribute(), ["t"])).to(beFalse())

                expect(passes(StartsWithOperator.self, PropertyAttribute("number"), ["12"])).to(beTrue())
                expect(passes(StartsWithOperator.self, PropertyAttribute("true"), ["tru"])).to(beTrue())
                expect(passes(StartsWithOperator.self, PropertyAttribute("false"), ["alse"])).to(beFalse())
                expect(passes(StartsWithOperator.self, PropertyAttribute("nil"), ["nil"])).to(beFalse())
                expect(passes(StartsWithOperator.self, PropertyAttribute("missing"), ["nil"])).to(beFalse())
                expect(passes(StartsWithOperator.self, TimestampAttribute(), ["123"])).to(beTrue())
            }
        }

        describe("ends with operator") {
            it("should pass correctly") {
                expect(passes(EndsWithOperator.self, PropertyAttribute("string"), ["e"])).to(beFalse())
                expect(passes(EndsWithOperator.self, PropertyAttribute("number"), ["e"])).to(beFalse())
                expect(passes(EndsWithOperator.self, PropertyAttribute("true"), ["e"])).to(beTrue())
                expect(passes(EndsWithOperator.self, PropertyAttribute("false"), ["e"])).to(beTrue())
                expect(passes(EndsWithOperator.self, PropertyAttribute("nil"), ["e"])).to(beFalse())
                expect(passes(EndsWithOperator.self, PropertyAttribute("missing"), ["e"])).to(beFalse())
                expect(passes(EndsWithOperator.self, TimestampAttribute(), ["e"])).to(beFalse())

                expect(passes(EndsWithOperator.self, PropertyAttribute("number"), ["12"])).to(beFalse())
                expect(passes(EndsWithOperator.self, PropertyAttribute("true"), ["tru"])).to(beFalse())
                expect(passes(EndsWithOperator.self, PropertyAttribute("false"), ["alse"])).to(beTrue())
                expect(passes(EndsWithOperator.self, PropertyAttribute("nil"), ["nil"])).to(beFalse())
                expect(passes(EndsWithOperator.self, PropertyAttribute("missing"), ["nil"])).to(beFalse())
                expect(passes(EndsWithOperator.self, TimestampAttribute(), ["0"])).to(beTrue())
            }
        }

        describe("regex operator") {
            it("should pass correctly") {
                let pattern = "^(some)*(123)*(thing)*"
                expect(passes(RegexOperator.self, PropertyAttribute("string"), [pattern])).to(beTrue())
                expect(passes(RegexOperator.self, PropertyAttribute("number"), [pattern])).to(beTrue())
                expect(passes(RegexOperator.self, PropertyAttribute("true"), [pattern])).to(beTrue())
                expect(passes(RegexOperator.self, PropertyAttribute("false"), [pattern])).to(beTrue())
                expect(passes(RegexOperator.self, PropertyAttribute("nil"), [pattern])).to(beFalse())
                expect(passes(RegexOperator.self, PropertyAttribute("missing"), [pattern])).to(beFalse())
                expect(passes(RegexOperator.self, TimestampAttribute(), [pattern])).to(beTrue())

                expect(passes(RegexOperator.self, PropertyAttribute("string"), [""])).to(beFalse())
                expect(passes(RegexOperator.self, PropertyAttribute("string"), ["test"])).to(beFalse())
                expect(passes(RegexOperator.self, PropertyAttribute("string"), ["^someX*thing$"])).to(beTrue())
                expect(passes(RegexOperator.self, PropertyAttribute("string"), ["^someX+thing$"])).to(beFalse())
            }
        }
    }
}
