//
//  TrackingParametersSpec.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 31/07/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDKShared

class TrackingParametersSpec: QuickSpec {
    override func spec() {
        describe("A tracking parameter") {
            context("Setting group of parameters to track") {

                let mockData = MockData()

                let param = TrackingParameters(
                    customerIds: mockData.customerIds,
                    properties: mockData.properties,
                    timestamp: nil,
                    eventType: nil)

                it("Should return a [String: JSONValue] type") {
                    expect(param.parameters).to(beAKindOf([String: JSONValue].self))
                }

                it("Should not return nil") {
                    expect(param.parameters).toNot(beNil())
                }
            }
        }
    }
}
