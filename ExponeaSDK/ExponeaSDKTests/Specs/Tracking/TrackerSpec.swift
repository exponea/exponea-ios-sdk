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

        describe("A tracker") {

            //let database = DatabaseManager()
            //let configuration = APIConfiguration(baseURL: Constants.Repository.baseURL,
//                                                 contentType: Constants.Repository.contentType)
            //let repository = ConnectionManager(configuration: configuration)

            context("After being properly initialized") {
                //let trackingManager = TrackingManager(database: database, repository: repository)
                it("Should not track install event") {
                    // TODO: Implement after find a way to test CoreData calls.
                }
            }
        }
    }
}
