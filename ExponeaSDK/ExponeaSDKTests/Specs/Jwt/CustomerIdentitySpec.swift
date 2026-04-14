//
//  CustomerIdentitySpec.swift
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

class CustomerIdentitySpec: QuickSpec {

    override func spec() {

        describe("CustomerIdentity") {

            context("initialization") {

                it("should create context with customer IDs and JWT") {
                    let context = CustomerIdentity(
                        customerIds: ["registered": "test@example.com", "external_id": "12345"],
                        jwtToken: "mock.jwt.token"
                    )

                    expect(context.customerIds).to(equal([
                        "registered": "test@example.com",
                        "external_id": "12345"
                    ]))
                    expect(context.jwtToken).to(equal("mock.jwt.token"))
                }

                it("should create context with customer IDs only") {
                    let context = CustomerIdentity(
                        customerIds: ["registered": "test@example.com"]
                    )

                    expect(context.customerIds).to(equal(["registered": "test@example.com"]))
                    expect(context.jwtToken).to(beNil())
                }

                it("should create context with JWT only") {
                    let context = CustomerIdentity(jwtToken: "mock.jwt.token")

                    expect(context.customerIds).to(beEmpty())
                    expect(context.jwtToken).to(equal("mock.jwt.token"))
                }

                it("should create empty context") {
                    let context = CustomerIdentity()

                    expect(context.customerIds).to(beEmpty())
                    expect(context.jwtToken).to(beNil())
                }
            }

            context("computed properties") {

                it("hasCustomerIds should return true when customer IDs exist") {
                    let context = CustomerIdentity(customerIds: ["registered": "test@example.com"])

                    expect(context.hasCustomerIds).to(beTrue())
                }

                it("hasCustomerIds should return false when customer IDs are empty") {
                    let context = CustomerIdentity(customerIds: [:])

                    expect(context.hasCustomerIds).to(beFalse())
                }

                it("hasJwtToken should return true when JWT is set") {
                    let context = CustomerIdentity(jwtToken: "mock.jwt.token")

                    expect(context.hasJwtToken).to(beTrue())
                }

                it("hasJwtToken should return false when JWT is nil") {
                    let context = CustomerIdentity()

                    expect(context.hasJwtToken).to(beFalse())
                }

                it("hasJwtToken should return false when JWT is empty string") {
                    var context = CustomerIdentity()
                    context.jwtToken = ""

                    expect(context.hasJwtToken).to(beFalse())
                }
            }

            context("mutability") {

                it("should allow updating customerIds") {
                    var context = CustomerIdentity()

                    context.customerIds = ["registered": "updated@example.com"]

                    expect(context.customerIds).to(equal(["registered": "updated@example.com"]))
                }

                it("should allow updating jwtToken") {
                    var context = CustomerIdentity()

                    context.jwtToken = "new.jwt.token"

                    expect(context.jwtToken).to(equal("new.jwt.token"))
                }

                it("should allow incremental building") {
                    var context = CustomerIdentity()

                    context.customerIds["registered"] = "test@example.com"
                    context.customerIds["external_id"] = "12345"
                    context.jwtToken = "mock.jwt.token"

                    expect(context.customerIds.count).to(equal(2))
                    expect(context.hasJwtToken).to(beTrue())
                }
            }

            context("Equatable") {

                it("should be equal when all properties match") {
                    let context1 = CustomerIdentity(
                        customerIds: ["registered": "test@example.com"],
                        jwtToken: "mock.jwt.token"
                    )
                    let context2 = CustomerIdentity(
                        customerIds: ["registered": "test@example.com"],
                        jwtToken: "mock.jwt.token"
                    )

                    expect(context1).to(equal(context2))
                }

                it("should not be equal when customerIds differ") {
                    let context1 = CustomerIdentity(customerIds: ["registered": "test1@example.com"])
                    let context2 = CustomerIdentity(customerIds: ["registered": "test2@example.com"])

                    expect(context1).notTo(equal(context2))
                }

                it("should not be equal when jwtToken differs") {
                    let context1 = CustomerIdentity(jwtToken: "token1")
                    let context2 = CustomerIdentity(jwtToken: "token2")

                    expect(context1).notTo(equal(context2))
                }
            }

            context("Codable") {

                it("should encode and decode correctly") {
                    let original = CustomerIdentity(
                        customerIds: ["registered": "test@example.com", "external_id": "12345"],
                        jwtToken: "mock.jwt.token"
                    )

                    do {
                        let encoded = try JSONEncoder().encode(original)
                        let decoded = try JSONDecoder().decode(CustomerIdentity.self, from: encoded)

                        expect(decoded).to(equal(original))
                    } catch {
                        fail("Encoding/decoding failed: \(error)")
                    }
                }

                it("should encode and decode empty context") {
                    let original = CustomerIdentity()

                    do {
                        let encoded = try JSONEncoder().encode(original)
                        let decoded = try JSONDecoder().decode(CustomerIdentity.self, from: encoded)

                        expect(decoded).to(equal(original))
                    } catch {
                        fail("Encoding/decoding failed: \(error)")
                    }
                }

                it("should encode and decode context with nil JWT") {
                    let original = CustomerIdentity(customerIds: ["registered": "test@example.com"])

                    do {
                        let encoded = try JSONEncoder().encode(original)
                        let decoded = try JSONDecoder().decode(CustomerIdentity.self, from: encoded)

                        expect(decoded).to(equal(original))
                        expect(decoded.jwtToken).to(beNil())
                    } catch {
                        fail("Encoding/decoding failed: \(error)")
                    }
                }
            }
        }
    }
}
