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
    }
}
