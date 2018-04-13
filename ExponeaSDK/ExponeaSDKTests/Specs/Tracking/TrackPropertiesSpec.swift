//
//  TrackPropertiesSpec.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 13/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class TrackPropertiesSpec: QuickSpec {

    override func spec() {
        describe("Track customer property update") {
            context("ExponeaSDK not configured") {
                let data = TrackMockData()
                it("Event call should return false") {
                    let result = Exponea.shared.trackCustomerProperties(customerId: data.customerId,
                                                                        properties: data.properties,
                                                                        timestamp: data.timestamp)
                    expect(result).to(beFalse())
                }
            }
        }
    }
}
