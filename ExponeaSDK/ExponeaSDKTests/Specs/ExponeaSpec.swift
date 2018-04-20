//
//  ExponeaSpec.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 29/03/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import XCTest
import Quick
import Nimble

@testable import ExponeaSDK

class ExponeaSpec: QuickSpec {

    override func spec() {

        let database = MockDatabase()

        describe("A SDK") {

            context("After beign initialized") {
                let exponea = Exponea(database: database)
                it("Should not be configured") {
                    expect(exponea.configured).to(beFalse())
                }
                it("Should not return a project token") {
                    expect(exponea.projectToken).to(beNil())
                }
                it("Should return the default value for timeout") {
                    expect(exponea.sessionTimeout).toNot(equal(Constants.Session.defaultTimeout))
                }
            }

            context("After beign configured from string") {
                let exponea = Exponea(database: database)
                exponea.configure(projectToken: "0aef3a96-3804-11e8-b710-141877340e97",
                                  authorization: "Basic")
                it("Should be configured") {
                    expect(exponea.configured).to(beTrue())
                }
                it("Should have a project token") {
                    expect(exponea.projectToken).toNot(beNil())
                }
                it("Should return the correct project token") {
                    expect(exponea.projectToken).to(equal("0aef3a96-3804-11e8-b710-141877340e97"))
                }
            }

            context("After beign configured from plist file") {
                let exponea = Exponea(database: database)
                exponea.configure(plistName: "ExponeaConfig")
                it("Should have a project token") {
                    expect(exponea.projectToken).toNot(beNil())
                }
                it("Should return the correct project token") {
                    expect(exponea.projectToken).to(equal("0aef3a96-3804-11e8-b710-141877340e97"))
                }
            }

            context("Setting exponea properties") {
                let exponea = Exponea(database: database)
                exponea.configure(plistName: "ExponeaConfig")
                exponea.projectToken = "NewProjectToken"
                it("Should return the new token") {
                    expect(exponea.projectToken).to(equal("NewProjectToken"))
                }
                it("Should return true for auto tracking") {
                    exponea.autoSessionTracking = true
                    expect(exponea.autoSessionTracking).to(beTrue())
                }
            }

        }
    }
}
