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
                    {"operands":[],"operator":"is set","type":"string"}
                    """
                ),
                (
                    StringConstraint.isNotSet,
                    """
                    {"operands":[],"operator":"is not set","type":"string"}
                    """
                ),
                (
                    StringConstraint.hasValue,
                    """
                    {"operands":[],"operator":"has value","type":"string"}
                    """
                ),
                (
                    StringConstraint.hasNoValue,
                    """
                    {"operands":[],"operator":"has no value","type":"string"}
                    """
                ),
                (
                    StringConstraint.equals("asdf"),
                    """
                    {"operands":[{"type":"constant","value":"asdf"}],"operator":"equals","type":"string"}
                    """
                ),
                (
                    StringConstraint.doesNotEqual("asdf"),
                    """
                    {"operands":[{"type":"constant","value":"asdf"}],"operator":"does not equal","type":"string"}
                    """
                ),
                (
                    StringConstraint.isIn(["asdf"]),
                    """
                    {"operands":[{"type":"constant","value":"asdf"}],"operator":"in","type":"string"}
                    """
                ),
                (
                    StringConstraint.notIn(["asdf"]),
                    """
                    {"operands":[{"type":"constant","value":"asdf"}],"operator":"not in","type":"string"}
                    """
                ),
                (
                    StringConstraint.contains("asdf"),
                    """
                    {"operands":[{"type":"constant","value":"asdf"}],"operator":"contains","type":"string"}
                    """
                ),
                (
                    StringConstraint.doesNotContain("asdf"),
                    """
                    {"operands":[{"type":"constant","value":"asdf"}],"operator":"does not contain","type":"string"}
                    """
                ),
                (
                    StringConstraint.startsWith("asdf"),
                    """
                    {"operands":[{"type":"constant","value":"asdf"}],"operator":"starts with","type":"string"}
                    """
                ),
                (
                    StringConstraint.endsWith("asdf"),
                    """
                    {"operands":[{"type":"constant","value":"asdf"}],"operator":"ends with","type":"string"}
                    """
                ),
                (
                    StringConstraint.regex("asdf"),
                    """
                    {"operands":[{"type":"constant","value":"asdf"}],"operator":"regex","type":"string"}
                    """
                ),
                // number
                (
                    NumberConstraint.isSet,
                    """
                    {"operands":[],"operator":"is set","type":"number"}
                    """
                ),
                (
                    NumberConstraint.isNotSet,
                    """
                    {"operands":[],"operator":"is not set","type":"number"}
                    """
                ),
                (
                    NumberConstraint.hasValue,
                    """
                    {"operands":[],"operator":"has value","type":"number"}
                    """
                ),
                (
                    NumberConstraint.hasNoValue,
                    """
                    {"operands":[],"operator":"has no value","type":"number"}
                    """
                ),
                (
                    NumberConstraint.equalTo(123),
                    """
                    {"operands":[{"type":"constant","value":"123.0"}],"operator":"equal to","type":"number"}
                    """
                ),
                (
                    NumberConstraint.lessThan(123),
                    """
                    {"operands":[{"type":"constant","value":"123.0"}],"operator":"less than","type":"number"}
                    """
                ),
                (
                    NumberConstraint.greaterThan(123),
                    """
                    {"operands":[{"type":"constant","value":"123.0"}],"operator":"greater than","type":"number"}
                    """
                ),
                (// swiftlint:disable line_length
                    NumberConstraint.inBetween(123, 456),
                    """
                    {"operands":[{"type":"constant","value":"123.0"},{"type":"constant","value":"456.0"}],"operator":"in between","type":"number"}
                    """
                ),
                (
                    NumberConstraint.notBetween(123, 456),
                    """
                    {"operands":[{"type":"constant","value":"123.0"},{"type":"constant","value":"456.0"}],"operator":"not between","type":"number"}
                    """
                ), // swiftlint:enable line_length
                //boolean
                (
                    BooleanConstraint.isSet,
                    """
                    {"operator":"is set","type":"boolean","value":"true"}
                    """
                ),
                (
                    BooleanConstraint.isNotSet,
                    """
                    {"operator":"is not set","type":"boolean","value":"true"}
                    """
                ),
                (
                    BooleanConstraint.hasValue,
                    """
                    {"operator":"has value","type":"boolean","value":"true"}
                    """
                ),
                (
                    BooleanConstraint.hasNoValue,
                    """
                    {"operator":"has no value","type":"boolean","value":"true"}
                    """
                ),
                (
                    BooleanConstraint.itIs(false),
                    """
                    {"operator":"is","type":"boolean","value":"false"}
                    """
                )
            ]
            // swiftlint:enable open_brace_spacing close_brace_spacing
            testCases.forEach { testCase in
                let testCaseName = "\(testCase.0.type) constraint with \(testCase.0.filterOperator.name) operator"

                it("should create and correctly serialize \(testCaseName)") {
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = [.sortedKeys]
                    let encodedData = try! encoder.encode(EventFilterConstraintCoder(testCase.0))
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
