//
//  JwtErrorContextSpec.swift
//  ExponeaSDKTests
//
//  Created by Bloomreach on 03/02/2026.
//  Copyright © 2026 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK
@testable import ExponeaSDKShared

class JwtErrorContextSpec: QuickSpec {

    override func spec() {

        describe("JwtErrorContext") {

            context("initialization") {

                it("should create context with reason only") {
                    let context = JwtErrorContext(reason: .expired)
                    expect(context.reason).to(equal(.expired))
                    expect(context.customerIds).to(beNil())
                }

                it("should create context with reason and customerIds") {
                    let ids = ["cookie": "uuid-1", "registered": "user@example.com"]
                    let context = JwtErrorContext(reason: .notProvided, customerIds: ids)
                    expect(context.reason).to(equal(.notProvided))
                    expect(context.customerIds).to(equal(ids))
                }

                it("should create context with reason and nil customerIds explicitly") {
                    let context = JwtErrorContext(reason: .invalid, customerIds: nil)
                    expect(context.reason).to(equal(.invalid))
                    expect(context.customerIds).to(beNil())
                }
            }

            context("Reason enum") {

                it("should have notProvided case") {
                    let context = JwtErrorContext(reason: .notProvided)
                    expect(context.reason).to(equal(.notProvided))
                }

                it("should have invalid case") {
                    let context = JwtErrorContext(reason: .invalid)
                    expect(context.reason).to(equal(.invalid))
                }

                it("should have expired case") {
                    let context = JwtErrorContext(reason: .expired)
                    expect(context.reason).to(equal(.expired))
                }

                it("should have expiredSoon case") {
                    let context = JwtErrorContext(reason: .expiredSoon)
                    expect(context.reason).to(equal(.expiredSoon))
                }

                it("should have insufficient case") {
                    let context = JwtErrorContext(reason: .insufficient)
                    expect(context.reason).to(equal(.insufficient))
                }
            }

            context("customerIds") {

                it("should preserve empty dictionary") {
                    let context = JwtErrorContext(reason: .expired, customerIds: [:])
                    expect(context.customerIds).to(equal([:]))
                }

                it("should preserve multiple customer ids") {
                    let ids = ["cookie": "c1", "email": "e@x.com", "registered": "r1"]
                    let context = JwtErrorContext(reason: .invalid, customerIds: ids)
                    expect(context.customerIds).to(equal(ids))
                }
            }
        }
    }
}
