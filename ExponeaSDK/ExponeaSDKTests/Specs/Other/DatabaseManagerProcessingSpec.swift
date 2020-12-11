//
//  DatabaseManagerProcessingSpec.swift
//  ExponeaSDKTests
//
//  Created by Dominik Hadl on 01/08/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import XCTest
import Quick
import Nimble

@testable import ExponeaSDK

class DatabaseManagerProcessingSpec: QuickSpec {
    override func spec() {
        describe("Database object conversion") {
            context("from primitive value to JSONValue", {
                it("should work for strings", closure: {
                    let string = NSString(string: "mystring")
                    let output = DatabaseManager.transformPrimitiveType(string)
                    expect(output) == .string("mystring")
                })

                it("should work for bool", closure: {
                    let number = NSNumber(value: true)
                    let output = DatabaseManager.transformPrimitiveType(number)
                    expect(output) == .bool(true)
                })

                it("should work for int", closure: {
                    let number = NSNumber(value: 1234)
                    let output = DatabaseManager.transformPrimitiveType(number)
                    expect(output) == .int(1234)
                })

                it("should work for double", closure: {
                    let number = NSNumber(value: 1234.56)
                    let output = DatabaseManager.transformPrimitiveType(number)
                    expect(output) == .double(1234.56)
                })

                it("should not work for unsupported type", closure: {
                    let object = NSObject()
                    let output = DatabaseManager.transformPrimitiveType(object)
                    expect(output).to(beNil())
                })
            })

            context("from NSArray to JSONValue", {
                it("should work with simple array", closure: {
                    let array = NSArray(array: [123, "mystring", true])
                    let output = DatabaseManager.processArray(array)
                    let expected: JSONValue = .array([
                        .int(123),
                        .string("mystring"),
                        .bool(true)
                        ])
                    expect(output).to(equal(expected))
                })

                it("should work with nested arrays", closure: {
                    let array: NSArray =  [
                        123,
                        "mystring",
                        [456.74, "nestedstring", ["doublenested"]],
                        true
                    ]
                    let output = DatabaseManager.processArray(array)
                    let expected: JSONValue = .array([
                        .int(123),
                        .string("mystring"),
                        .array([
                            .double(456.74),
                            .string("nestedstring"),
                            .array([.string("doublenested")])
                            ]),
                        .bool(true)
                        ])
                    expect(output).to(equal(expected))
                })

                it("should work with empty array", closure: {
                    let array = NSArray(array: [])
                    let output = DatabaseManager.processArray(array)
                    expect(output).to(equal(.array([])))
                })
            })

            context("from NSDictionary to JSONValue", {
                it("should work with simple dictionary", closure: {
                    let dictionary = NSDictionary(dictionary: [
                        "intvalue": 123,
                        "stringvalue": "mystring",
                        "boolvalue": true
                        ])

                    let output = DatabaseManager.processDictionary(dictionary)
                    let expected: JSONValue = .dictionary([
                        "intvalue": .int(123),
                        "stringvalue": .string("mystring"),
                        "boolvalue": .bool(true)
                        ])
                    expect(output).to(equal(expected))
                })

                it("should work with nested arrays and dictionaries", closure: {
                    let dictionary = NSDictionary(dictionary: [
                        "intvalue": 123,
                        "stringvalue": "mystring",
                        "arrayvalue": [234.56, "arraystring"],
                        "dictionaryvalue": ["nestedkey": "nestedvalue"],
                        "boolvalue": true
                        ])

                    let output = DatabaseManager.processDictionary(dictionary)
                    let expected: JSONValue = .dictionary([
                        "intvalue": .int(123),
                        "stringvalue": .string("mystring"),
                        "arrayvalue": .array([
                            .double(234.56),
                            .string("arraystring")
                            ]),
                        "dictionaryvalue": .dictionary([
                            "nestedkey": .string("nestedvalue")
                            ]),
                        "boolvalue": .bool(true)
                        ])
                    expect(output).to(equal(expected))
                })

                it("should work with empty dictionary", closure: {
                    let dictionary = NSDictionary(dictionary: [:])
                    let output = DatabaseManager.processDictionary(dictionary)
                    expect(output).to(equal(.dictionary([:])))
                })

                it("should not work for non string keys", closure: {
                    let dictionary = NSDictionary(dictionary: [123: "test"])
                    let output = DatabaseManager.processDictionary(dictionary)
                    expect(output).to(equal(.dictionary([:])))
                })

                it("should not work for non object values", closure: {
                    class TestClass { }
                    let dictionary = NSDictionary(dictionary: ["key": TestClass()])
                    let output = DatabaseManager.processDictionary(dictionary)
                    expect(output).to(equal(.dictionary([:])))
                })
            })

            context("from root NSObject to JSONvalue", {
                it("should handle dictionaries", closure: {
                    let dictionary = NSDictionary(dictionary: ["key": "value"])
                    let output = DatabaseManager.processObject(dictionary)
                    expect(output) == .dictionary(["key": .string("value")])
                })

                it("should handle arrays", closure: {
                    let array = NSArray(array: [123, "mystring", true])
                    let output = DatabaseManager.processObject(array)
                    let expected: JSONValue = .array([.int(123), .string("mystring"), .bool(true)])
                    expect(output).to(equal(expected))
                })

                it("should handle primitive types", closure: {
                    let number = NSNumber(value: 1234.56)
                    let output = DatabaseManager.processObject(number)
                    expect(output) == .double(1234.56)
                })

                it("should not parse unsupported types", closure: {
                    expect(DatabaseManager.processObject(NSSet())).to(beNil())
                })
            })
        }
    }
}
