//
//  EventSpec.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 01/08/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class EventSpec: QuickSpec {
    override func spec() {
        describe("A event") {

            let mock = MockData()

            context("Setting the event values") {

                let event = mock.event

                it("Type should be purchase") {
                    expect(event.type).to(equal("purchase"))
                }

                it("Should contain two properties") {
                    expect(event.properties?.count).to(equal(2))
                }

                it("Description should contain data from structure") {
                    expect(event.description).toEventually(contain(["purchase",
                                                                    "iPad",
                                                                    "Tablet"]))
                }
            }
        }
    }
}
