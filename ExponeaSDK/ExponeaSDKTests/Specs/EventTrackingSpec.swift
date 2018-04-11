//
//  EventTrackingSpec.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 11/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class EventTrackingSpec: QuickSpec {

    override func spec() {

        describe("Tracking an event") {

            // Preparing data to interact with tracking event process
            let customer = KeyValueModel(key: "registered", value: "John Doe")
            let properties = [KeyValueModel(key: "price", value: 1234.50),
                              KeyValueModel(key: "name", value: "iPad")]

            context("Project not configured") {
                it("Data should not be stored into CoreData") {

                    let exponea = Exponea(dbManager: MockEntitiesManager())
                    exponea.configure(projectToken: "123")
                }
            }

            context("Setting up an event and send it to CoreData") {
                it("Data should be sent to CoreData") {
                    Exponea.configure(projectToken: "ProjectToken2018")
                }
            }
        }
    }

}
