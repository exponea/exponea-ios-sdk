//
//  SwizzleSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 06/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Nimble
import Quick

@testable import ExponeaSDK

final class SwizzlerSpec: QuickSpec {
    override func spec() {
        afterEach {
            Swizzler.swizzles.forEach {
                Swizzler.unswizzle($0.value)
            }
        }

        it("should swizzle and unswizzle") {
            Swizzler.swizzleSelector(
                #selector(SwizzleTestClass.getResult),
                with: #selector(SwizzleTestClass.getOtherResult),
                for: SwizzleTestClass.self,
                name: "test swizzle",
                block: {_, _, _ in }
            )

            expect(SwizzleTestClass().getResult()).to(equal("other result"))
            expect(SwizzleTestClass().getOtherResult()).to(equal("other result"))

            Swizzler.unswizzleSelector(#selector(SwizzleTestClass.getResult), aClass: SwizzleTestClass.self)

            expect(SwizzleTestClass().getResult()).to(equal("result"))
            expect(SwizzleTestClass().getOtherResult()).to(equal("other result"))
        }

        it("should get swizzle") {
            Swizzler.swizzleSelector(
                #selector(SwizzleTestClass.getResult),
                with: #selector(SwizzleTestClass.getOtherResult),
                for: SwizzleTestClass.self,
                name: "test swizzle",
                block: {_, _, _ in }
            )
            let swizzle = Swizzler.getSwizzle(for:
                class_getInstanceMethod(SwizzleTestClass.self, #selector(SwizzleTestClass.getResult))!
            )
            expect(swizzle?.name).to(equal("test swizzle"))
            expect(swizzle?.description).to(equal("Swizzle on ExponeaSDKTests.SwizzleTestClass::getResult [test swizzle,]"))
        }
    }
}
