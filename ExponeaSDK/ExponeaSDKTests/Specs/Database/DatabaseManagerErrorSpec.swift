//
//  DatabaseManagerErrorSpec.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 01/08/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class DatabaseManagerErrorSpec: QuickSpec {
    override func spec() {
        describe("A database manager") {
            context("Database error handling") {

                it("Should return a [String: Object does not exist.]") {
                    let error = DatabaseManagerError.objectDoesNotExist
                    expect(error.errorDescription).to(equal("Object does not exist."))
                }

                it("Should return a [String: The object you want to modify is of different type than expected.]") {
                    let error = DatabaseManagerError.wrongObjectType
                    expect(error.errorDescription).to(
                        equal("The object you want to modify is of different type than expected.")
                    )
                }

                it("Should return a [String: Saving a new customer failed: No ID Found.]") {
                    let error = DatabaseManagerError.saveCustomerFailed("No ID Found")
                    expect(error.errorDescription).to(equal("Saving a new customer failed: No ID Found."))
                }

                it("Should return a [String: Unknown error. Database not available]") {
                    let error = DatabaseManagerError.unknownError("Database not available")
                    expect(error.errorDescription).to(equal("Unknown database error: Database not available"))
                }

                it("Should return a [String: Unknown error.") {
                    let error = DatabaseManagerError.unknownError(nil)
                    expect(error.errorDescription).to(equal("Unknown database error: N/A"))
                }
            }
        }
    }
}
