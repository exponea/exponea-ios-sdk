//
//  TrackerSpec.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 12/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class TrackerSpec: QuickSpec {

    override func spec() {

//        let mockContainer = MockPersistentContainer()
//        let configuration = APIConfiguration(baseURL: Constants.Repository.baseURL,
//                                             contentType: Constants.Repository.contentType)
//        let repository = ConnectionManager(configuration: configuration)
//        let exponea = Exponea(repository: repository, container: mockContainer.persistantContainer)
//        let data = TrackMockData()

        describe("A tracker") {

            context("After beign initialized") {
                // FIXME: Find out how to use stubs instead of coredata classes.
//                let customerEvent = exponea.trackCustomerEvent(customerId: data.customerId,
//                                                               properties: data.properties,
//                                                               timestamp: data.timestamp,
//                                                               eventType: "purchase")
                //expect(customerEvent).to(beTrue())
            }
        }
    }
}
