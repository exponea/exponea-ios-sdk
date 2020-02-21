//
//  UIColor+FromHexStringSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 05/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Nimble
import Quick

@testable import ExponeaSDK

final class UIColorFromHexStringSpec: QuickSpec {
    override func spec() {
        it("should parse valid colors") {
            expect(UIColor(fromHexString: "#000000"))
                .to(equal(UIColor(red: 0, green: 0, blue: 0, alpha: 1)))
            expect(UIColor(fromHexString: "#FF0000"))
                .to(equal(UIColor(red: 1, green: 0, blue: 0, alpha: 1)))
            expect(UIColor(fromHexString: "#00ffFF"))
                .to(equal(UIColor(red: 0, green: 1, blue: 1, alpha: 1)))
        }
        it("should return black on invalid colors") {
            expect(UIColor(fromHexString: "0"))
                .to(equal(UIColor(red: 0, green: 0, blue: 0, alpha: 1)))
            expect(UIColor(fromHexString: "xxx"))
                .to(equal(UIColor(red: 0, green: 0, blue: 0, alpha: 1)))
            expect(UIColor(fromHexString: "#xxxxxx"))
                .to(equal(UIColor(red: 0, green: 0, blue: 0, alpha: 1)))
            expect(UIColor(fromHexString: "random string"))
                .to(equal(UIColor(red: 0, green: 0, blue: 0, alpha: 1)))
        }
    }
}
