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
        describe("Conversion from JSONConvertible") {
            context("with Bool") {
                it("should be equal", closure: {
                    let bool = true
                    expect(bool.jsonValue).to(equal(.bool(true)))
                })
            }
            context("with Int") {
                it("should be equal", closure: {
                    let number = 12345
                    expect(number.jsonValue).to(equal(.int(12345)))
                })
            }
            context("with Double") {
                it("should be equal", closure: {
                    let number = 12345.678
                    expect(number.jsonValue).to(equal(.double(12345.678)))
                })
            }
            context("with String") {
                it("should be equal", closure: {
                    let string = "my string"
                    expect(string.jsonValue).to(equal(.string("my string")))
                })
            }
            context("with NSString") {
                it("should be equal", closure: {
                    let string = NSString(string: "my string")
                    expect(string.jsonValue).to(equal(.string("my string")))
                })
            }
            context("with array") {
                it("should be equal", closure: {
                    let array = [JSONValue.int(123), JSONValue.string("string"), JSONValue.bool(true)]
                    expect(array.jsonValue).to(equal(.array([.int(123), .string("string"), .bool(true)])))
                })
            }
            context("with dictionary") {
                it("should be equal", closure: {
                    let dictionary: [String: JSONValue] = [
                        "intvalue": .int(123),
                        "stringvalue": .string("myvalue"),
                        "boolvalue": .bool(true)
                    ]
                    let expected = JSONValue.dictionary([
                        "intvalue": .int(123),
                        "stringvalue": .string("myvalue"),
                        "boolvalue": .bool(true)
                        ])
                    expect(dictionary.jsonValue).to(equal(expected))
                })
            }
        }

        describe("Conversion to JSONConvertible") {
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
                    let array = val.jsonConvertible as? [JSONValue]
                    let converted = array?.map({ $0.jsonConvertible })

                    expect(converted?.first).to(beAKindOf(Int.self))

                    let int = converted?.first as? Int
                    expect(int).to(equal(123))
                })
            }
            context("with dictionary") {
                it("should be equal", closure: {
                    let val = JSONValue.dictionary(["test": .string("value")])
                    expect(val.jsonConvertible).to(beAKindOf(Dictionary<String, JSONValue>.self))

                    let dict = val.jsonConvertible as? [String: JSONValue]
                    let converted = dict?.mapValues({ $0.jsonConvertible })

                    expect(converted?["test"]).to(beAKindOf(String.self))

                    let string = converted?["test"] as? String
                    expect(string).to(equal("value"))
                })
            }

        }

        describe("JSONValue comparisons") {
            context("between same cases", {
                it("should succeed if cases and values are equal", closure: {
                    expect(JSONValue.double(123.45)).toNot(equal(JSONValue.string("mystring")))
                })

                it("should not succeed if value is different", closure: {
                    expect(JSONValue.double(123.45)).toNot(equal(JSONValue.double(123.456)))
                })
            })
            context("between different cases", {
                it("should not succeed", closure: {
                    expect(JSONValue.double(123.45)).toNot(equal(JSONValue.string("mystring")))
                })
            })
        }

        describe("Conversion to NSObject") {
            context("with bool", {
                it("should return correct NSNumber", closure: {
                    let val = JSONValue.bool(true)
                    let object = val.objectValue
                    expect(object).to(beAKindOf(NSNumber.self))

                    let num = object as? NSNumber
                    expect(num?.boolValue).to(equal(true))
                })
            })

            context("with int", {
                it("should return correct NSNumber", closure: {
                    let val = JSONValue.int(1234)
                    let object = val.objectValue
                    expect(object).to(beAKindOf(NSNumber.self))

                    let num = object as? NSNumber
                    expect(num?.intValue).to(equal(1234))
                })
            })

            context("with double", {
                it("should return correct NSNumber", closure: {
                    let val = JSONValue.double(1234.56)
                    let object = val.objectValue
                    expect(object).to(beAKindOf(NSNumber.self))

                    let num = object as? NSNumber
                    expect(num?.doubleValue).to(equal(1234.56))
                })
            })

            context("with string", {
                it("should return NSString", closure: {
                    let val = JSONValue.string("mystring")
                    let object = val.objectValue
                    expect(object).to(beAKindOf(NSString.self))

                    let str = object as? NSString
                    expect(str).to(equal("mystring"))
                })
            })

            context("with array", {
                it("should return NSArray", closure: {
                    let val = JSONValue.array([.string("myvalue")])
                    let object = val.objectValue
                    expect(object).to(beAKindOf(NSArray.self))

                    let array = object as? NSArray
                    expect(array?.firstObject).to(beAKindOf(NSString.self))

                    let str = array?.firstObject as? NSString
                    expect(str).to(equal("myvalue"))
                })
            })

            context("with dictionary", {
                it("should return NSDictionary", closure: {
                    let val = JSONValue.dictionary(["mykey": .string("myvalue")])
                    let object = val.objectValue
                    expect(object).to(beAKindOf(NSDictionary.self))

                    let dict = object as? NSDictionary
                    expect(dict?["mykey"]).to(beAKindOf(NSString.self))

                    let str = dict?["mykey"] as? NSString
                    expect(str).to(equal("myvalue"))
                })
            })
        }

        describe("Conversion to raw value") {
            context("with bool", {
                it("should return Bool", closure: {
                    let val = JSONValue.bool(true)
                    let object = val.rawValue
                    expect(object).to(beAKindOf(Bool.self))

                    let num = object as? Bool
                    expect(num).to(equal(true))
                })
            })

            context("with int", {
                it("should return Int", closure: {
                    let val = JSONValue.int(1234)
                    let object = val.rawValue
                    expect(object).to(beAKindOf(Int.self))

                    let num = object as? Int
                    expect(num).to(equal(1234))
                })
            })

            context("with double", {
                it("should return Double", closure: {
                    let val = JSONValue.double(1234.56)
                    let object = val.rawValue
                    expect(object).to(beAKindOf(Double.self))

                    let num = object as? Double
                    expect(num).to(equal(1234.56))
                })
            })

            context("with string", {
                it("should return String", closure: {
                    let val = JSONValue.string("mystring")
                    let object = val.rawValue
                    expect(object).to(beAKindOf(String.self))

                    let str = object as? String
                    expect(str).to(equal("mystring"))
                })
            })

            context("with array", {
                it("should return Array", closure: {
                    let val = JSONValue.array([.string("myvalue")])
                    let object = val.rawValue
                    expect(object).to(beAKindOf(Array<Any>.self))

                    let array = object as? [Any]
                    expect(array?.first).to(beAKindOf(String.self))

                    let str = array?.first as? String
                    expect(str).to(equal("myvalue"))
                })
            })

            context("with dictionary", {
                it("should return Dictionary", closure: {
                    let val = JSONValue.dictionary(["mykey": .string("myvalue")])
                    let object = val.rawValue
                    expect(object).to(beAKindOf(Dictionary<AnyHashable, Any>.self))

                    let dict = object as? [AnyHashable: Any]
                    expect(dict?["mykey"]).to(beAKindOf(String.self))

                    let str = dict?["mykey"] as? String
                    expect(str).to(equal("myvalue"))
                })
            })
        }

        describe("Decoding from JSON") {
            context("with valid data", {
                class TestClass: Codable {
                    let boolValue: JSONValue
                    let intValue: JSONValue
                    let doubleValue: JSONValue
                    let stringValue: JSONValue
                    let arrayValue: JSONValue
                    let dictionaryValue: JSONValue
                }
                let json = """
                    {
                        "boolValue" : true,
                        "intValue" : 1234,
                        "doubleValue" : 1234.56,
                        "stringValue" : "test",
                        "arrayValue" : [123, "string", true],
                        "dictionaryValue" : { "dictkey" : "dictval" }
                    }
                    """
                let decoded = try! JSONDecoder().decode(TestClass.self, from: json.data(using: .utf8)!)

                it("should parse Bool", closure: {
                    expect(decoded.boolValue).to(equal(JSONValue.bool(true)))
                })
                it("should parse Int", closure: {
                    expect(decoded.intValue).to(equal(JSONValue.int(1234)))
                })
                it("should parse Double", closure: {
                    expect(decoded.doubleValue).to(equal(JSONValue.double(1234.56)))
                })
                it("should parse String", closure: {
                    expect(decoded.stringValue).to(equal(JSONValue.string("test")))
                })
                it("should parse Array", closure: {
                    expect(decoded.arrayValue).to(equal(JSONValue.array([.int(123), .string("string"), .bool(true)])))
                })
                it("should parse Dictionary", closure: {
                    expect(decoded.dictionaryValue).to(equal(JSONValue.dictionary(["dictkey": .string("dictval")])))
                })
            })
        }

        describe("Encoding to JSON") {
            context("with valid data", {
                let encoder = JSONEncoder()

                class TestClass: Codable {
                    let value: JSONValue

                    init(value: JSONValue) {
                        self.value = value
                    }
                }

                it("should encode Bool", closure: {
                    let value = TestClass(value: JSONValue.bool(true))
                    let data = try! encoder.encode(value)
                    let encoded = String(data: data, encoding: .utf8)
                    expect(encoded).to(equal("{\"value\":true}"))
                })

                it("should encode Int", closure: {
                    let value = TestClass(value: JSONValue.int(1234))
                    let data = try! encoder.encode(value)
                    let encoded = String(data: data, encoding: .utf8)
                    expect(encoded).to(equal("{\"value\":1234}"))
                })

                it("should encode Double", closure: {
                    let value = TestClass(value: JSONValue.double(1234.56))
                    let data = try! encoder.encode(value)
                    let encoded = String(data: data, encoding: .utf8)
                    expect(encoded).to(equal("{\"value\":1234.5599999999999}"))
                })

                it("should encode String", closure: {
                    let value = TestClass(value: JSONValue.string("test"))
                    let data = try! encoder.encode(value)
                    let encoded = String(data: data, encoding: .utf8)
                    expect(encoded).to(equal("{\"value\":\"test\"}"))
                })

                it("should encode Array", closure: {
                    let value = TestClass(value: JSONValue.array([.string("test"), .int(1234)]))
                    let data = try! encoder.encode(value)
                    let encoded = String(data: data, encoding: .utf8)
                    expect(encoded).to(equal("{\"value\":[\"test\",1234]}"))
                })

                it("should encode Dictionary", closure: {
                    let value = TestClass(value: JSONValue.dictionary(["key": .int(1234),
                                                                       "other": .string("string")]))
                    let data = try! encoder.encode(value)
                    let encoded = String(data: data, encoding: .utf8)
                    expect(encoded).to(contain("\"key\":1234"))
                    expect(encoded).to(contain("\"other\":\"string\""))
                    expect(encoded).to(contain("{\"value\":{"))
                })
            })
        }
    }
}
