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

        describe("A SDK") {
            context("After beign initialized") {
                let exponea = Exponea()
                it("Should return a nil configuration") {
                    expect(exponea.configuration?.projectToken).to(beNil())
                }
            }
            context("After beign configured from string") {
                let exponea = Exponea()
                Exponea.shared = exponea
                Exponea.shared.configure(projectToken: "0aef3a96-3804-11e8-b710-141877340e97", authorization: .basic(""))
                
                it("Should return the correct project token") {
                    expect(exponea.configuration?.projectToken).to(equal("0aef3a96-3804-11e8-b710-141877340e97"))
                }
            }
            context("After beign configured from plist file") {
                let exponea = Exponea()
                Exponea.shared = exponea
                Exponea.shared.configure(plistName: "ExponeaConfig")
                
                it("Should have a project token") {
                    expect(exponea.configuration?.projectToken).toNot(beNil())
                }
                it("Should return the correct project token") {
                    expect(exponea.configuration?.projectToken).to(equal("0aef3a96-3804-11e8-b710-141877340e97"))
                }
                it("Should return the default base url") {
                    expect(exponea.configuration?.baseUrl).to(equal("https://api.exponea.com"))
                }
            }
            context("Setting exponea properties") {
                let exponea = Exponea()
                Exponea.shared = exponea
                Exponea.shared.configure(plistName: "ExponeaConfig")
                
                exponea.configuration?.projectToken = "NewProjectToken"
                exponea.configuration?.baseUrl = "NewBaseURL"
                it("Should return the new token") {
                    expect(exponea.configuration?.projectToken).to(equal("NewProjectToken"))
                }
                it("Should return true for auto tracking") {
                    exponea.configuration?.automaticSessionTracking = true
                    expect(exponea.configuration?.automaticSessionTracking).to(beTrue())
                }
                it("Should change the base url") {
                    expect(exponea.configuration?.baseUrl).to(equal("NewBaseURL"))
                }
            }
        }
    }
}
