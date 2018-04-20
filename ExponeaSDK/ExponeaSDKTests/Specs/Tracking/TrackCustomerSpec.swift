//
//  TrackCustomerSpec.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 17/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class TrackCustomerSpec: QuickSpec {

    // TODO: Finish implementation of unit tests with coredata tests
    override func spec() {
        describe("A Track Customer") {
            let data = TrackMockData()
            context("ExponeaSDK not configured") {
//                it("Event call should return false") {
//                    let result = Exponea.shared.trackCustomer(customerId: data.customerId,
//                                                              properties: data.properties,
//                                                              timestamp: data.timestamp)
//                    expect(result).to(beFalse())
//                }
            }
        }
    }
}
