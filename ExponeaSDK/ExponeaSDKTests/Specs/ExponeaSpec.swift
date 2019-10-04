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
            context("Before being configured") {
                var exponea = Exponea()
                beforeEach {
                    exponea = Exponea()
                }

                it("Should return a nil configuration") {
                    expect(exponea.configuration?.projectToken).to(beNil())
                }
                it("Should get flushing mode") {
                    guard case .manual = exponea.flushingMode else {
                        XCTFail("Expected .manual got \(exponea.flushingMode)")
                        return
                    }
                }
                it("Should not crash setting flushing mode") {
                    expect(exponea.flushingMode = .immediate).notTo(raiseException())
                }
                it("Should return empty pushNotificationsDelegate") {
                    expect(exponea.pushNotificationsDelegate).to(beNil())
                }
                it("Should not crash tracking event") {
                    expect(exponea.trackEvent(properties: [:], timestamp: nil, eventType: nil)).notTo(raiseException())
                }
                it("Should not crash tracking campaign click") {
                    expect(exponea.trackCampaignClick(url: URL(string: "mockUrl")!, timestamp: nil)).notTo(raiseException())
                }
                it("Should not crash tracking payment") {
                    expect(exponea.trackPayment(properties: [:], timestamp: nil)).notTo(raiseException())
                }
                it("Should not crash identifing customer") {
                    expect(exponea.identifyCustomer(customerIds: [:], properties: [:], timestamp: nil)).notTo(raiseException())
                }
                it("Should not crash tracking push token") {
                    expect(exponea.trackPushToken("token".data(using: .utf8)!)).notTo(raiseException())
                    expect(exponea.trackPushToken("token")).notTo(raiseException())
                }
                it("Should not crash tracking push opened") {
                    expect(exponea.trackPushOpened(with: [:])).notTo(raiseException())
                }
                it("Should not crash tracking session") {
                    expect(exponea.trackSessionStart()).notTo(raiseException())
                    expect(exponea.trackSessionEnd()).notTo(raiseException())
                }
                it("Should fail fetching recommendation") {
                    waitUntil { done in
                        exponea.fetchRecommendation(with: RecommendationRequest(type: "mock_type", id: "mock_id")) { response in
                            guard case .failure = response else {
                                XCTFail("Expected .failure got \(response)")
                                done()
                                return
                            }
                            done()
                        }
                    }
                }
                it("Should fail fetching data") {
                    waitUntil { done in
                        exponea.fetchBanners { response in
                            guard case .failure = response else {
                                XCTFail("Expected .failure got \(response)")
                                done()
                                return
                            }
                            done()
                        }
                    }
                }
                it("Should fail fetching personalization") {
                    waitUntil { done in
                        exponea.fetchPersonalization(with: PersonalizationRequest(ids: [])) { response in
                            guard case .failure = response else {
                                XCTFail("Expected .failure got \(response)")
                                done()
                                return
                            }
                            done()
                        }
                    }
                }
                it("Should fail fetching consents") {
                    waitUntil { done in
                        exponea.fetchConsents { response in
                            guard case .failure = response else {
                                XCTFail("Expected .failure got \(response)")
                                done()
                                return
                            }
                            done()
                        }
                    }
                }
                it("Should not crash anonymizing") {
                    expect(exponea.anonymize()).notTo(raiseException())
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

            context("Setting pushNotificationsDelegate") {
                Exponea.logger = MockLogger()
                class MockDelegate: PushNotificationManagerDelegate {
                    func pushNotificationOpened(with action: ExponeaNotificationActionType,
                                                value: String?, extraData: [AnyHashable: Any]?) {}
                }
                it("Should log warning before Exponea is configured") {
                    let exponea = Exponea()
                    let delegate = MockDelegate()
                    exponea.pushNotificationsDelegate = delegate
                    expect(exponea.pushNotificationsDelegate).to(beNil())
                    expect(MockLogger.messages.last)
                        .to(match("Cannot set push notifications delegate."))
                }
                it("Should set delegate after Exponea is configured") {
                    let exponea = Exponea()
                    exponea.configure(plistName: "ExponeaConfig")
                    let delegate = MockDelegate()
                    MockLogger.messages.removeAll()
                    exponea.pushNotificationsDelegate = delegate
                    expect(exponea.pushNotificationsDelegate).to(be(delegate))
                    expect(MockLogger.messages).to(beEmpty())
                }
            }
        }
    }
}
