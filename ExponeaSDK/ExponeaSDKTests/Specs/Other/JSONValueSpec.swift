//
//  JSONValueSpec.swift
//  ExponeaSDKTests
//
//  Created by Dominik Hadl on 31/07/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import XCTest
import Quick
import Nimble

@testable import ExponeaSDK

class JSONValueSpec: QuickSpec {

    override func spec() {
        describe("Conversion from JSONConvertible to JSONValue ") {
            context("with bool") {
                it("should be equal", closure: {
                    let bool = true
                    expect(bool.jsonValue).to(equal(.bool(true)))
                })
            }
            context("with integer") {
                it("should be equal", closure: {
                    let number = 12345
                    expect(number.jsonValue).to(equal(.int(12345)))
                })
            }
            context("with double") {
                it("should be equal", closure: {
                    let number = 12345.678
                    expect(number.jsonValue).to(equal(.double(12345.678)))
                })
            }
            context("with string") {
                it("should be equal", closure: {
                    let string = "my string"
                    expect(string.jsonValue).to(equal(.string("my string")))
                })
            }
            context("with array") {
                it("should be equal", closure: {
//                    let rawArray: [JSONConvertible] = [123, "my string", true]
//                    let conv: JSONValue = rawArray.jsonValue
                    
                    let array = [JSONValue.int(123), JSONValue.string("string"), JSONValue.bool(true)]
                    expect(array.jsonValue).to(equal(.array([.int(123), .string("string"), .bool(true)])))
                    
                    
                })
            }
            context("with dictionary") {
                it("should be equal", closure: {
                    let dictionary: [String: JSONValue] = [
                        "intvalue" : .int(123),
                        "stringvalue" : .string("myvalue"),
                        "boolvalue" : .bool(true)
                    ]
                    expect(dictionary.jsonValue).to(equal(.dictionary(["intvalue" : .int(123), "stringvalue" : .string("myvalue"), "boolvalue" : .bool(true)])))
                    
                })
            }
        }
        
        describe("Conversion from JSONValue to JSONConvertible") {
            context("with bool") {
                it("should be equal", closure: {
                    let val = JSONValue.bool(true)
                    expect(val.jsonConvertible).to(beAKindOf(Bool.self))
                    let bool = val.jsonConvertible as? Bool
                    expect(bool).to(equal(true))
                })
            }
            context("with integer") {
                it("should be equal", closure: {
                    let val = JSONValue.int(1234)
                    expect(val.jsonConvertible).to(beAKindOf(Int.self))
                    let int = val.jsonConvertible as? Int
                    expect(int).to(equal(1234))
                })
            }
            context("with double") {
                it("should be equal", closure: {
                    let val = JSONValue.double(1234.56)
                    expect(val.jsonConvertible).to(beAKindOf(Double.self))
                    let double = val.jsonConvertible as? Double
                    expect(double).to(equal(1234.56))
                })
            }
            context("with string") {
                it("should be equal", closure: {
                    let val = JSONValue.string("mystring")
                    expect(val.jsonConvertible).to(beAKindOf(String.self))
                    let string = val.jsonConvertible as? String
                    expect(string).to(equal("mystring"))
                })
            }
            context("with array") {
                it("should be equal", closure: {
                    let val = JSONValue.array([.int(123), .string("string"), .bool(true)])
                    expect(val.jsonConvertible).to(beAKindOf(Array<JSONValue>.self))
                    let array = val.jsonConvertible as? Array<JSONValue>
                    let converted = array?.map({ $0.jsonConvertible })
                    let expected: [JSONConvertible] = [123, "mystring", true]
//                    expect(converted).to(equal(expected))
//                    expect(converted).to(eq)
                })
            }
            context("with dictionary") {
                it("should be equal", closure: {
                    
                })
            }
        }
        
    }
    
}
