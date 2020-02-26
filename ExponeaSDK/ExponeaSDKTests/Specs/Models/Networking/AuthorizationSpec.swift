//
//  AuthorizationSpec.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 01/08/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class AuthorizationSpec: QuickSpec {
    override func spec() {
        describe("A authorization") {
            context("Header authorization type none") {
                let authorization = Authorization.none

                it("Should return a [String: No Authorization]") {
                    expect(authorization.description).to(equal("No Authorization"))
                }

                it("Should return a [String: No Authorization]") {
                    expect(authorization.debugDescription).to(equal("No Authorization"))
                }
            }

            context("Header authorization type basic") {
                let authorization = Authorization.token("123")

                it("Should return a [String: Token Authorization (token redacted)]") {
                    expect(authorization.description).to(equal("Token Authorization (token redacted)"))
                }

                it("Should return a [String: Token Authorization (Basic 123)]") {
                    expect(authorization.debugDescription).to(equal("Token Authorization (123)"))
                }
            }
        }
    }
}
