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
                    let rawArray: [JSONConvertible] = [123, "my string", true]
                    let conv: JSONValue = rawArray.jsonValue
                    
                    let array: JSONConvertible = [JSONValue.int(123), JSONValue.string("string"), JSONValue.bool(true)]
                    expect(array.jsonValue).to(equal(.array([.int(123), .string("string"), .bool(true)])))
                    
                    
                })
            }
            context("with dictionary") {
                it("should be equal", closure: {
                    let rawDictionary: [AnyHashable: Any] = [
                        "intvalue" : 123,
                        "stringvalue" : "myvalue",
                        "boolvalue" : true
                    ]
                    
                    
                })
            }
        }
        
        describe("Conversion from JSONValue to JSONConvertible") {
            context("with bool") {
                it("should be equal", closure: {
                    
                })
            }
            context("with integer") {
                it("should be equal", closure: {
                    
                })
            }
            context("with double") {
                it("should be equal", closure: {
                    
                })
            }
            context("with string") {
                it("should be equal", closure: {
                    
                })
            }
            context("with array") {
                it("should be equal", closure: {
                    
                })
            }
            context("with dictionary") {
                it("should be equal", closure: {
                    
                })
            }
        }
        
    }
    
}
