//
//  FetchEventsSpec.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 18/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class FetchEventsSpec: QuickSpec {

    // TODO: Finish implementation of unit tests with mock data
    override func spec() {

        let database = MockDatabase()
        let data = FetchMockData()
        let configuration = try! Configuration(plistName: "ExponeaConfig")
        let repository = ServerRepository(configuration: configuration)
/*
        let exponea = Exponea()
        Exponea.shared = exponea
        Exponea.shared.configure(plistName: "ExponeaConfig")
        // FIXME: Fix injection
        exponea.trackingManager = TrackingManager(repository: repository, database: database, userDefaults: UserDefaults.standard)
        exponea.repository = repository

        describe("Fetch Event") {
            //var returnData: Result<Events>?

            expect(exponea.configuration?.authorization).toNot(beNil())
            waitUntil(timeout: 5) { done in
                Exponea.shared.fetchEvents(with: data.customerData, completion: { (result) in
                    it("Should not return error") {
                        expect(result.error).to(beNil())
                    }
                    it("Should return success") {
                        expect(result.value?.success).to(beTrue())
                    }
                    // FIXME: API returning 0 values
//                    it("Should return any response") {
//                        expect(result.value?.data?.count).to(beGreaterThan(0))
//                    }
                    done()
                })
            }
        }
 */
    }
}
