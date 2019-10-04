//
//  RequestParametersTypeSpec.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 01/08/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class RequestParametersTypeSpec: QuickSpec {
    override func spec() {
        describe("A request parameter protocol") {
            context("Defining a class to be conform to protocol") {

                let testClass = RequestParametersTypeTest()

                it("Should be a kind of [RequestParametersType]") {
                    expect(testClass).to(beAKindOf(RequestParametersType.self))
                }

                it("Parameters should have one parameter [first_name]") {
                    let param = testClass.requestParameters["first_name"] as? String
                    expect(param).to(equal("John"))
                }
            }
        }
    }
}

class RequestParametersTypeTest: RequestParametersType {
    var parameters: [String: JSONValue] = ["first_name": .string("John")]
}
