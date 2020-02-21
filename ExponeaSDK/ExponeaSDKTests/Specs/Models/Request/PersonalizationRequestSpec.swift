//
//  PersonalizationRequestSpec.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 01/08/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class PersonalizationRequestSpec: QuickSpec {
    override func spec() {
        describe("A personalization request") {
            context("Defining a list with personalization requests") {
                let personalization = MockData.init().personalizationRequest

                it("timeout should contain values [Int: 5") {
                    let params = personalization.parameters["timeout"]
                    expect(params).to(equal(.int(5)))
                }

                it("timezone should contain values [String: GMT+2") {
                    let params = personalization.parameters["timezone"]
                    expect(params).to(equal(.string("GMT+2")))
                }

                it("param should be nil") {
                    let params = personalization.parameters["params"]
                    expect(params).to(beNil())
                }
            }
        }
    }
}
