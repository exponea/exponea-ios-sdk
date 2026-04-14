//
//  SequenceTest.swift
//  ExponeaSDKTests
//
//  Created by Ankmara on 18.07.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Nimble
import Quick

@testable import ExponeaSDK

final class SequenceTest: QuickSpec {

    class Test {}

    override func spec() {
        var test: Test?
        it("remove nil") {
            var arrayA: [Any] = ["test", "test1", test, [test, 1, "2", nil], ["value": test, "name": "john"]]
            var dic: [String: Any] = ["test": test, "data": arrayA, "test2": ["ok": test, "number": 1, "string": "test", "optional": test]]
            let arrayACount = arrayA.removeNill().count
            let dictionaryCount = dic.removeNill().count
            expect(arrayACount).to(equal(4))
            let arrayAtIndex3 = (arrayA.removeNill()[2] as! [Any]).count
            expect(arrayAtIndex3).to(equal(2))
            let dicAtIndex4 = (arrayA.removeNill()[3] as! [String: Any]).count
            expect(dicAtIndex4).to(equal(1))
            let json = try? JSONSerialization.data(withJSONObject: dic.removeNill(), options: [])
            expect(json).toNot(beNil())
        }
        it("compare string dics") {
            let dic1 = ["reason": "test1", "house": "test2", "car": "test3", "home": "test4"]
            var dic2 = ["house": "test2", "home": "test4", "reason": "test1", "car": "test3"]
            expect(dic1.compareWith(other: dic2)).to(beTrue())
            dic2["house"] = "testss2"
            expect(dic1.compareWith(other: dic2)).to(beFalse())
        }
        it("should keep sequences intact") {
            let array = [1, true, "hello", [1, true, "hello"], ["value": "ok", "name": "john"]]
            let normalized = array.removeNill()
            expect(array.count).to(equal(5))
            expect((array[3] as? [Any])?.count ?? 0).to(equal(3))
            expect((array[4] as? [String: Any])?.count ?? 0).to(equal(2))
        }
        it("remove sub-level nils") {
            let data: [String: Any] = [
                "key1": 1,
                "key2": true,
                "key3": "hello",
                "key4": [1, true, "hello", nil, [1, true, "hello", nil]],
                "key5": [
                    "key5-1": 1,
                    "key5-2": true,
                    "key5-3": "hello",
                    "key5-4": nil,
                    "key5-5": [1, true, "hello", nil, [1, true, "hello", nil]],
                    "key5-6": [
                        "key5-6-1": 1,
                        "key5-6-2": true,
                        "key5-6-3": "hello",
                        "key5-6-4": nil
                    ]
                ]
            ]
            let normalized = data.removeNill()
            let key4Array = normalized["key4"] as? [Any?]
            expect(key4Array).toNot(beNil())
            expect(key4Array?.count ?? 0).to(equal(4))
            expect((key4Array?[3] as? [Any?])?.count ?? 0).to(equal(3))
            let key5Dic = normalized["key5"] as? [String: Any?]
            expect(key5Dic).toNot(beNil())
            expect(key5Dic?["key5-4"]).to(beNil())
            let key55Array = key5Dic?["key5-5"] as? [Any?]
            expect(key55Array).toNot(beNil())
            expect(key55Array?.count ?? 0).to(equal(4))
            expect((key55Array?[3] as? [Any?])?.count ?? 0).to(equal(3))
            let key56Dic = key5Dic?["key5-6"] as? [String: Any?]
            expect(key56Dic).toNot(beNil())
            expect(key56Dic?.count ?? 0).to(equal(3))
            expect(key56Dic?["key5-6-4"]).to(beNil())
            let json = try? JSONSerialization.data(withJSONObject: normalized, options: [])
            expect(json).toNot(beNil())
        }
        it("remove all-level infinities") {
            let data: [String: Any] = [
                "key1": 1,
                "key2": true,
                "key3": "hello",
                "keyDoubleInifinity": Double.infinity,
                "keyFloatInifinity": Float.infinity,
                "key4": [1, true, "hello", Double.infinity, Float.infinity, [1, true, "hello", Double.infinity, Float.infinity]],
                "key5": [
                    "key5-1": 1,
                    "key5-2": true,
                    "key5-3": "hello",
                    "key5-4-double": Double.infinity,
                    "key5-4-float": Float.infinity,
                    "key5-5": [1, true, "hello", Double.infinity, Float.infinity, [1, true, "hello", Double.infinity, Float.infinity]],
                    "key5-6": [
                        "key5-6-1": 1,
                        "key5-6-2": true,
                        "key5-6-3": "hello",
                        "key5-6-4-double": Double.infinity,
                        "key5-6-4-float": Float.infinity
                    ]
                ]
            ]
            let normalized = data.removeInfinity()
            expect(normalized["keyDoubleInifinity"]).to(beNil())
            expect(normalized["keyFloatInifinity"]).to(beNil())
            let key4Array = normalized["key4"] as? [Any?]
            expect(key4Array).toNot(beNil())
            expect(key4Array?.count ?? 0).to(equal(4))
            expect((key4Array?[3] as? [Any?])?.count ?? 0).to(equal(3))
            let key5Dic = normalized["key5"] as? [String: Any?]
            expect(key5Dic).toNot(beNil())
            expect(key5Dic?["key5-4-double"]).to(beNil())
            expect(key5Dic?["key5-4-float"]).to(beNil())
            let key55Array = key5Dic?["key5-5"] as? [Any?]
            expect(key55Array).toNot(beNil())
            expect(key55Array?.count ?? 0).to(equal(4))
            expect((key55Array?[3] as? [Any?])?.count ?? 0).to(equal(3))
            let key56Dic = key5Dic?["key5-6"] as? [String: Any?]
            expect(key56Dic).toNot(beNil())
            expect(key56Dic?.count ?? 0).to(equal(3))
            expect(key56Dic?["key5-6-4-double"]).to(beNil())
            expect(key56Dic?["key5-6-4-float"]).to(beNil())
            let json = try? JSONSerialization.data(withJSONObject: normalized, options: [])
            expect(json).toNot(beNil())
        }
    }
}
