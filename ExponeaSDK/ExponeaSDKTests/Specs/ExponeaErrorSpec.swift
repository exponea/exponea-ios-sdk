//
//  ExponeaErrorSpec.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 31/07/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class ExponeaErrorSpec: QuickSpec {
    override func spec() {
        describe("A Exponea error") {

            context("Check for every error level") {

                it("Error not configured") {
                    let exponeaError = ExponeaError.notConfigured
                    expect(exponeaError.localizedDescription).to(equal(Constants.ErrorMessages.sdkNotConfigured))
                }

                it("Configured error") {
                    let exponeaError = ExponeaError.configurationError("Error Description")
                    let errorDesc = """
                    The provided configuration contains error(s). \
                    Please, fix them before initialising Exponea SDK.
                    Error Description
                    """
                    expect(exponeaError.localizedDescription).to(equal(errorDesc))
                }

                it("Unknow error") {
                    let exponeaError = ExponeaError.unknownError("Unknown")
                    let errorDesc = "Unknown error. Unknown"
                    expect(exponeaError.localizedDescription).to(equal(errorDesc))
                }
            }

        }
    }
}
