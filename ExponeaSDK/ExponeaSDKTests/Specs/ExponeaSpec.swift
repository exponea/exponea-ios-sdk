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

        let configuration = APIConfiguration(baseURL: Constants.Repository.baseURL,
                                             contentType: Constants.Repository.contentType)
        let repository = ConnectionManager(configuration: configuration)

        let exponea = Exponea(database: MockEntitiesManager(), repository: repository)

        describe("Configure SDK") {

            context("After being properly initialized token with string") {
                it("Configuration with token string should be initialized") {
                    exponea.configure(projectToken: "123")
                    expect(exponea.configured).to(beTrue())
                    expect(exponea.projectToken).to(equal("123"))
                }
            }
            context("After being properly initialized token with plist") {
                it("Configuration with plist token should be initialized") {
                    Exponea.configure(plistName: "ExponeaConfig.plist")
                    expect(exponea.configured).to(beTrue())
                    expect(exponea.projectToken).to(equal("ExponeaProjectIdKeyFromPList"))
                }
            }
        }

        describe("Check projectId (token)") {

            Exponea.configure(plistName: "ExponeaConfig.plist")

            context("Get projectId (token) after it's being setup") {
                it("ProjectId string should be returned") {
                    expect(exponea.projectToken).notTo(beNil())
                    expect(exponea.projectToken).to(equal("ExponeaProjectIdKeyFromPList"))
                }
            }
            context("Update projectId (token)") {
                it("ProjectId should be updated") {
                    let oldProjectId = exponea.projectToken
                    exponea.projectToken = "NewProjectId"
                    let newProjectId = exponea.projectToken
                    expect(oldProjectId).notTo(equal(newProjectId))
                    expect(newProjectId).to(equal("NewProjectId"))
                }
            }
        }
    }
}
