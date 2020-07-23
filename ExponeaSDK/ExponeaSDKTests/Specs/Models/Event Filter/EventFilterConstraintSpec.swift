//
//  EventFilterConstraintSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 06/02/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import XCTest
import Quick
import Nimble

@testable import ExponeaSDK

final class EventFilterConstraintSpec: QuickSpec {
    override func spec() {
        describe("serialization") {
            // swiftlint:enable:next open_brace_spacing close_brace_spacing
            let testCases: [(EventFilterConstraint, String)] = [
                // string
                (
                    StringConstraint.isSet,
                    """
                    {"type":"string","operator":"is set","operands":[]}
                    """
                ),
                (
                    StringConstraint.isNotSet,
                    """
                    {"type":"string","operator":"is not set","operands":[]}
                    """
                ),
                (
                    StringConstraint.hasValue,
                    """
                    {"type":"string","operator":"has value","operands":[]}
                    """
                ),
                (
                    StringConstraint.hasNoValue,
                    """
                    {"type":"string","operator":"has no value","operands":[]}
                    """
                ),
                (
                    StringConstraint.equals("asdf"),
                    """
                    {"type":"string","operator":"equals","operands":[{"type":"constant","value":"asdf"}]}
                    """
                ),
                (
                    StringConstraint.doesNotEqual("asdf"),
                    """
                    {"type":"string","operator":"does not equal","operands":[{"type":"constant","value":"asdf"}]}
                    """
                ),
                (
                    StringConstraint.isIn(["asdf"]),
                    """
                    {"type":"string","operator":"in","operands":[{"type":"constant","value":"asdf"}]}
                    """
                ),
                (
                    StringConstraint.notIn(["asdf"]),
                    """
                    {"type":"string","operator":"not in","operands":[{"type":"constant","value":"asdf"}]}
                    """
                ),
                (
                    StringConstraint.contains("asdf"),
                    """
                    {"type":"string","operator":"contains","operands":[{"type":"constant","value":"asdf"}]}
                    """
                ),
                (
                    StringConstraint.doesNotContain("asdf"),
                    """
                    {"type":"string","operator":"does not contain","operands":[{"type":"constant","value":"asdf"}]}
                    """
                ),
                (
                    StringConstraint.startsWith("asdf"),
                    """
                    {"type":"string","operator":"starts with","operands":[{"type":"constant","value":"asdf"}]}
                    """
                ),
                (
                    StringConstraint.endsWith("asdf"),
                    """
                    {"type":"string","operator":"ends with","operands":[{"type":"constant","value":"asdf"}]}
                    """
                ),
                (
                    StringConstraint.regex("asdf"),
                    """
                    {"type":"string","operator":"regex","operands":[{"type":"constant","value":"asdf"}]}
                    """
                ),
                // number
                (
                    NumberConstraint.isSet,
                    """
                    {"type":"number","operator":"is set","operands":[]}
                    """
                ),
                (
                    NumberConstraint.isNotSet,
                    """
                    {"type":"number","operator":"is not set","operands":[]}
                    """
                ),
                (
                    NumberConstraint.hasValue,
                    """
                    {"type":"number","operator":"has value","operands":[]}
                    """
                ),
                (
                    NumberConstraint.hasNoValue,
                    """
                    {"type":"number","operator":"has no value","operands":[]}
                    """
                ),
                (
                    NumberConstraint.equalTo(123),
                    """
                    {"type":"number","operator":"equal to","operands":[{"type":"constant","value":"123.0"}]}
                    """
                ),
                (
                    NumberConstraint.lessThan(123),
                    """
                    {"type":"number","operator":"less than","operands":[{"type":"constant","value":"123.0"}]}
                    """
                ),
                (
                    NumberConstraint.greaterThan(123),
                    """
                    {"type":"number","operator":"greater than","operands":[{"type":"constant","value":"123.0"}]}
                    """
                ),
                (// swiftlint:disable line_length
                    NumberConstraint.inBetween(123, 456),
                    """
                    {"type":"number","operator":"in between","operands":[{"type":"constant","value":"123.0"},{"type":"constant","value":"456.0"}]}
                    """
                ),
                (
                    NumberConstraint.notBetween(123, 456),
                    """
                    {"type":"number","operator":"not between","operands":[{"type":"constant","value":"123.0"},{"type":"constant","value":"456.0"}]}
                    """
                ), // swiftlint:enable line_length
                //boolean
                (
                    BooleanConstraint.isSet,
                    """
                    {"type":"boolean","operator":"is set","value":"true"}
                    """
                ),
                (
                    BooleanConstraint.isNotSet,
                    """
                    {"type":"boolean","operator":"is not set","value":"true"}
                    """
                ),
                (
                    BooleanConstraint.hasValue,
                    """
                    {"type":"boolean","operator":"has value","value":"true"}
                    """
                ),
                (
                    BooleanConstraint.hasNoValue,
                    """
                    {"type":"boolean","operator":"has no value","value":"true"}
                    """
                ),
                (
                    BooleanConstraint.itIs(false),
                    """
                    {"type":"boolean","operator":"is","value":"false"}
                    """
                )
            ]
            // swiftlint:enable open_brace_spacing close_brace_spacing
            testCases.forEach { testCase in
                let testCaseName = "\(testCase.0.type) constraint with \(testCase.0.filterOperator.name) operator"

                it("should create and correctly serialize \(testCaseName)") {
                    let encodedData = try! JSONEncoder().encode(EventFilterConstraintCoder(testCase.0))
                    let encodedString = String(data: encodedData, encoding: .utf8)
                    expect(encodedString).to(equal(testCase.1))
                }

                it("should deserialize \(testCaseName)") {
                    let encodedData = testCase.1.data(using: .utf8)!
                    let coder = try! JSONDecoder().decode(EventFilterConstraintCoder.self, from: encodedData)
                    expect(coder).to(equal(EventFilterConstraintCoder(testCase.0)))
                }
            }
        }
    }
}
