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
        
        // Load the mock center, to prevent crashes
        _ = MockUserNotificationCenter.shared

        describe("Exponea SDK") {
            context("After being initialized") {
                let exponea = Exponea()
                it("Should return a nil configuration") {
                    expect(exponea.configuration?.projectToken).to(beNil())
                }
            }
            context("After being configured from string") {
                let exponea = Exponea()
                Exponea.shared = exponea
                Exponea.shared.configure(projectToken: "0aef3a96-3804-11e8-b710-141877340e97", authorization: .token(""))
                
                it("Should return the correct project token") {
                    expect(exponea.configuration?.projectToken).to(equal("0aef3a96-3804-11e8-b710-141877340e97"))
                }
            }
            context("After being configured from plist file") {
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
                it("Should return the default session timeout") {
                    expect(exponea.configuration?.sessionTimeout).to(equal(Constants.Session.defaultTimeout))
                }
            }
            
            context("After being configured from advanced plist file") {
                let exponea = Exponea()
                Exponea.shared = exponea
                Exponea.shared.configure(plistName: "config_valid")
                
                it("Should return a custom session timeout") {
                    expect(exponea.configuration?.sessionTimeout).to(equal(20.0))
                }
                
                it("Should return automatic session tracking disabled") {
                    expect(exponea.configuration?.automaticSessionTracking).to(beFalse())
                }
                
                it("Should return automatic push tracking disabled") {
                    expect(exponea.configuration?.automaticPushNotificationTracking).to(beFalse())
                }
            }
            
            context("Setting exponea properties after configuration") {
                let exponea = Exponea()
                Exponea.shared = exponea
                Exponea.shared.configure(plistName: "ExponeaConfig")
                
                exponea.configuration?.projectToken = "NewProjectToken"
                exponea.configuration?.baseUrl = "NewBaseURL"
                exponea.configuration?.sessionTimeout = 25.0
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
                it("Should change the session timeout") {
                    expect(exponea.configuration?.sessionTimeout).to(equal(25))
                }
            }
        }
    }
}
