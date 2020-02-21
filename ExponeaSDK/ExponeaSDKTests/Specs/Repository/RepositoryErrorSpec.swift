//
//  RepositoryErrorSpec.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 01/08/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class RepositoryErrorSpec: QuickSpec {
    override func spec() {
        describe("A repository error") {

            context("Check for repository error level") {

                it("Missing data error description") {
                    let repoError = RepositoryError.missingData("ProductID")
                    let errorDesc = "Request is missing required data: ProductID"
                    expect(repoError.errorDescription).to(equal(errorDesc))
                }

                it("Invalid response error description") {
                    let repoError = RepositoryError.invalidResponse(nil)
                    let errorDesc = "An invalid response was received from the API: No response"
                    expect(repoError.errorDescription).to(equal(errorDesc))
                }

                it("Server error description") {
                    let repoError = RepositoryError.serverError(nil)
                    let errorDesc = "There was a server error, please try again later."
                    expect(repoError.errorDescription).to(equal(errorDesc))
                }

                it("URL not found error description") {
                    let repoError = RepositoryError.urlNotFound(nil)
                    let errorDesc = "Requested URL was not found."
                    expect(repoError.errorDescription).to(equal(errorDesc))
                }
            }

        }
    }
}
