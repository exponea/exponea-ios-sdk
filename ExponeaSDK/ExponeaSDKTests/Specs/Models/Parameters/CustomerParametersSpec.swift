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
                
                let param = CustomerParameters(
                    customer: mockData.customerIds,
                    property: "myProperty",
                    id: "123",
                    recommendation: nil,
                    attributes: nil,
                    events: nil,
                    data: nil)

                it("Should not return nil") {
                    expect(param.parameters).toNot(beEmpty())
                }
                
                it("Should get the property value from the parameters") {
                    let parameters = param.parameters
                    let value = parameters["property"]
                    expect(value).to(equal(.string("myProperty")))
                }
            }
        }
    }
}
