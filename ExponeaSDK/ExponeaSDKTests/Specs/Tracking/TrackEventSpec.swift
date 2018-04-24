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

    override func spec() {
        describe("Track a customer event") {
            let data = TrackMockData()
            let database = MockDatabase()
            let configuration = Configuration(plistName: "ExponeaConfig")!
            let repository = ConnectionManager(configuration: configuration)
            context("ExponeaSDK not configured") {
                it("Event call should return false") {
                    let exponea = Exponea(database: database,
                                          repository: repository)

                    let result = exponea.trackEvent(customerId: data.customerId,
                                                    properties: data.properties,
                                                    timestamp: data.timestamp,
                                                    eventType: "purchase")
                    expect(result).to(beFalse())
                }
            }
        }
    }
}
