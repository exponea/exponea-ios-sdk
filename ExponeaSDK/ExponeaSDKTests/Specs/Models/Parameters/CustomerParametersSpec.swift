//
//  CustomerParametersSpec.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 31/07/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class CustomerParametersSpec: QuickSpec {
    override func spec() {
        describe("A customer parameter") {
            
            context("Setting group of customer parameters to track") {
                
                let mockData = MockData()
                let param = mockData.customerParameters
                
                it("Should not return nil") {
                    expect(param.parameters).toNot(beEmpty())
                }
                
                it("Should get the value from the property key on parameters") {
                    let value = param.parameters["property"]
                    expect(value).to(equal(.string("myProperty")))
                }
                
                it("Should get the value for the id key on parameters") {
                    let value = param.parameters["id"]
                    expect(value).to(equal(.string("123")))
                }
            }
        }
    }
}
