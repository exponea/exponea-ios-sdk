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

        //let mockContainer = MockPersistentContainer()
        let configuration = APIConfiguration(baseURL: Constants.Repository.baseURL,
                                             contentType: Constants.Repository.contentType)
        let repository = ConnectionManager(configuration: configuration)

        describe("A SDK") {

            context("After beign initialized") {
                let exponea = Exponea(repository: repository)
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
                let exponea = Exponea(repository: repository)
                exponea.configure(projectToken: "ProjectTokenString")
                it("Should be configured") {
                    expect(exponea.configured).to(beTrue())
                }
                it("Should have a project token") {
                    expect(exponea.projectToken).toNot(beNil())
                }
                it("Should return the correct project token") {
                    expect(exponea.projectToken).to(equal("ProjectTokenString"))
                }
            }

            context("After beign configured from plist file") {
                let exponea = Exponea(repository: repository)
                exponea.configure(plistName: "ExponeaConfig.plist")
                it("Should have a project token") {
                    expect(exponea.projectToken).toNot(beNil())
                }
                it("Should return the correct project token") {
                    expect(exponea.projectToken).to(equal("ExponeaProjectIdKeyFromPList"))
                }
            }

            context("Setting exponea properties") {
                let exponea = Exponea(repository: repository)
                exponea.configure(plistName: "ExponeaConfig.plist")
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
