//
//  TrackEventSpec.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 13/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class TrackEventSpec: QuickSpec {

    // Preparing Mock Data
    let customerId = KeyValueModel(key: "registered", value: "john.doe@exponea.com")
    let properties = [KeyValueModel(key: "product_name", value: "iPad"),
                      KeyValueModel(key: "price", value: 999.99)]
    let timestamp = NSDate().timeIntervalSince1970

    override func spec() {
        describe("Track a event customer") {
            context("ExponeaSDK not configured") {
                it("Event call should return false") {
                    let result = Exponea.shared.trackCustomerEvent(customerId: self.customerId,
                                                                   properties: self.properties,
                                                                   timestamp: self.timestamp,
                                                                   eventType: "purchase")
                    expect(result).to(beFalse())
                }
            }
        }
    }
}
