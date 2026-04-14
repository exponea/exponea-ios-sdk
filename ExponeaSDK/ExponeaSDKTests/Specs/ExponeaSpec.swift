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
import ExponeaSDKObjC

@testable import ExponeaSDK
@testable import ExponeaSDKShared

class ExponeaSpec: QuickSpec {

    override func spec() {
        describe("Exponea SDK") {
            let configFileNames = ["ExponeaConfig", "ExponeaConfigStream"]
            
            context("Setting automaticSessionTracking after configuration") {
                for configFileName in configFileNames {
                    var exponea: ExponeaInternal!
                    
                    beforeEach {
                        IntegrationManager.shared.isStopped = false
                        let initExpectation = self.expectation(description: "Exponea automaticSessionTracking init")
                        exponea = ExponeaInternal().onInitSucceeded {
                            initExpectation.fulfill()
                        }
                        Exponea.shared = exponea
                        Exponea.shared.configure(plistName: configFileName)
                        self.wait(for: [initExpectation], timeout: 10)
                    }
                    
                    it("should configure automaticSessionTracking correctly") {
                        expect(exponea.configuration?.automaticSessionTracking).to(equal(true))
                        exponea.setAutomaticSessionTracking(automaticSessionTracking: Exponea.AutomaticSessionTracking.disabled)
                        expect(exponea.configuration?.automaticSessionTracking).to(equal(false))
                        exponea.setAutomaticSessionTracking(
                            automaticSessionTracking: Exponea.AutomaticSessionTracking.enabled(timeout: 30.0)
                        )
                        expect(exponea.configuration?.automaticSessionTracking).to(equal(true))
                        expect(exponea.configuration?.sessionTimeout).to(equal(30))
                    }
                }
            }

            context("Before being configured") {
                var exponea = ExponeaInternal()
                beforeEach {
                    IntegrationManager.shared.isStopped = false
                    exponea = ExponeaInternal()
                }

                it("debug mode combinations") {
                    expect(exponea.safeModeEnabled).to(beFalse())
                    exponea.isDebugModeEnabled = true
                    expect(exponea.safeModeEnabled).to(beFalse())
                    exponea.isDebugModeEnabled = false
                    expect(exponea.safeModeEnabled).to(beTrue())
                    exponea.safeModeEnabled = true
                    expect(exponea.safeModeEnabled).to(beTrue())
                    exponea.safeModeEnabled = true
                    exponea.isDebugModeEnabled = true
                    expect(exponea.safeModeEnabled).to(beTrue())
                }

                it("Should return a nil configuration") {
                    expect(exponea.configuration?.projectToken).to(beNil())
                    expect(exponea.configuration?.integrationId).to(beNil())
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
                    expect(exponea.trackCampaignClick(url: URL(sharedSafeString: "mockUrl")!, timestamp: nil))
                        .notTo(raiseException())
                }
                it("Should not crash tracking payment") {
                    expect(exponea.trackPayment(properties: [:], timestamp: nil)).notTo(raiseException())
                }
                it("Should not crash identifing customer") {
                    expect(exponea.identifyCustomer(
                        context: CustomerIdentity(customerIds: [:], jwtToken: nil),
                        properties: [:],
                        timestamp: nil
                    )).notTo(raiseException())
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
                it("Should not crash anonymizing") {
                    expect(exponea.anonymize()).notTo(raiseException())
                }
            }
            context("After being configured from string") {
                context("Config: integrationConfig - projectToken.") {
                    let exponea = ExponeaInternal()
                    Exponea.shared = exponea
                    Exponea.shared.configure(
                        Exponea.ProjectSettings(
                            projectToken: "0aef3a96-3804-11e8-b710-141877340e97",
                            authorization: .token("")
                        ),
                        pushNotificationTracking: .disabled
                    )
                    it("Should return the correct project token") {
                        expect(exponea.configuration?.integrationId).to(equal("0aef3a96-3804-11e8-b710-141877340e97"))
                    }
                }
                
                context("Config: integrationConfig - streamId.") {
                    let exponea = ExponeaInternal()
                    Exponea.shared = exponea
                    Exponea.shared.configure(
                        Exponea.StreamSettings(
                            streamId: "0aef3a96-3804-11e8-b710-141877340e97"
                        ),
                        pushNotificationTracking: .disabled
                    )
                    it("Should return the correct stream ID") {
                        expect(exponea.configuration?.integrationId).to(equal("0aef3a96-3804-11e8-b710-141877340e97"))
                    }
                }
            }
            context("After being configured from plist file") {
                context("Config: deprecated - projectToken.") {
                    let initExpectation = self.expectation(description: "Exponea internal init")
                    let exponea = ExponeaInternal().onInitSucceeded {
                        initExpectation.fulfill()
                    }
                                    
                    exponea.configure(plistName: "ExponeaConfig")
                    wait(for: [initExpectation], timeout: 10)
                    
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
                context("Config: integrationConfig - projectToken.") {
                    let initExpectation = self.expectation(description: "Exponea internal init")
                    let exponea = ExponeaInternal().onInitSucceeded {
                        initExpectation.fulfill()
                    }
                                    
                    exponea.configure(plistName: "ExponeaConfig")
                    wait(for: [initExpectation], timeout: 10)
                    
                    it("Should have a project token") {
                        expect(exponea.configuration?.integrationId).toNot(beNil())
                    }
                    it("Should return the correct project token") {
                        expect(exponea.configuration?.integrationId).to(equal("0aef3a96-3804-11e8-b710-141877340e97"))
                    }
                    it("Should return the default base url") {
                        expect(exponea.configuration?.integrationConfig.baseUrl).to(equal("https://api.exponea.com"))
                    }
                    it("Should return the default session timeout") {
                        expect(exponea.configuration?.sessionTimeout).to(equal(Constants.Session.defaultTimeout))
                    }
                }
                context("Config: integrationConfig - streamId.") {
                    let initExpectation = self.expectation(description: "Exponea internal init")
                    let exponea = ExponeaInternal().onInitSucceeded {
                        initExpectation.fulfill()
                    }
                                    
                    exponea.configure(plistName: "ExponeaConfigStream")
                    wait(for: [initExpectation], timeout: 10)
                    
                    it("Should have a stream ID") {
                        expect(exponea.configuration?.integrationId).toNot(beNil())
                    }
                    it("Should return the correct stream ID") {
                        expect(exponea.configuration?.integrationId).to(equal("0aef3a96-3804-11e8-b710-141877340e97"))
                    }
                    it("Should return the default base url") {
                        expect(exponea.configuration?.integrationConfig.baseUrl).to(equal("https://api.exponea.com"))
                    }
                    it("Should return the default session timeout") {
                        expect(exponea.configuration?.sessionTimeout).to(equal(Constants.Session.defaultTimeout))
                    }
                }
            }

            context("After being configured from advanced plist file") {
                for fileName in ["config_valid", "config_valid_stream"] {
                    context("Config file \(fileName)") {
                        let exponea = ExponeaInternal()
                        Exponea.shared = exponea
                        Exponea.shared.configure(plistName: fileName)

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
                }
            }

            context("Setting exponea properties after configuration") {
                context("Config: deprecated - projectToken.") {
                    let exponea = ExponeaInternal()
                    Exponea.shared = exponea
                    Exponea.shared.configure(plistName: "ExponeaConfig")
                    exponea.configuration?.projectToken = "NewProjectToken"
                    exponea.configuration?.baseUrl = "NewBaseURL"
                    exponea.configuration?.sessionTimeout = 25.0
                    expect(exponea.configuration?.projectToken).to(equal("NewProjectToken"))
                    exponea.configuration?.automaticSessionTracking = true
                    expect(exponea.configuration?.automaticSessionTracking).to(beTrue())
                    expect(exponea.configuration?.baseUrl).to(equal("NewBaseURL"))
                    expect(exponea.configuration?.sessionTimeout).to(equal(25))
                }
                context("Config: integrationConfig - projectToken.") {
                    let exponea = ExponeaInternal()
                    Exponea.shared = exponea
                    Exponea.shared.configure(plistName: "ExponeaConfig")
                    let previousAuth = (exponea.configuration?.integrationConfig as? Exponea.ProjectSettings)?.authorization ?? Authorization.none
                    exponea.configuration?.integrationConfig = Exponea.ProjectSettings(
                        projectToken: "NewProjectToken",
                        authorization: previousAuth,
                        baseUrl: "NewBaseURL"
                    )
                    exponea.configuration?.sessionTimeout = 25.0
                    expect(exponea.configuration?.integrationId).to(equal("NewProjectToken"))
                    exponea.configuration?.automaticSessionTracking = true
                    expect(exponea.configuration?.automaticSessionTracking).to(beTrue())
                    expect(exponea.configuration?.integrationConfig.baseUrl).to(equal("NewBaseURL"))
                    expect(exponea.configuration?.sessionTimeout).to(equal(25))
                }
                context("Config: integrationConfig - streamId.") {
                    let exponea = ExponeaInternal()
                    Exponea.shared = exponea
                    Exponea.shared.configure(plistName: "ExponeaConfigStream")
                    exponea.configuration?.integrationConfig = Exponea.StreamSettings(
                        streamId: "NewProjectToken",
                        baseUrl: "NewBaseURL"
                    )
                    exponea.configuration?.sessionTimeout = 25.0
                    expect(exponea.configuration?.integrationId).to(equal("NewProjectToken"))
                    exponea.configuration?.automaticSessionTracking = true
                    expect(exponea.configuration?.automaticSessionTracking).to(beTrue())
                    expect(exponea.configuration?.integrationConfig.baseUrl).to(equal("NewBaseURL"))
                    expect(exponea.configuration?.sessionTimeout).to(equal(25))
                }
            }

            context("Setting pushNotificationsDelegate") {
                var logger: MockLogger!
                beforeEach {
                    IntegrationManager.shared.isStopped = false
                    logger = MockLogger()
                    Exponea.logger = logger
                }
                class MockDelegate: PushNotificationManagerDelegate {
                    func pushNotificationOpened(with action: ExponeaNotificationActionType,
                                                value: String?, extraData: [AnyHashable: Any]?) {}
                }
                it("Should log warning before Exponea is configured") {
                    let exponea = ExponeaInternal()
                    let delegate = MockDelegate()
                    exponea.pushNotificationsDelegate = delegate
                    expect(exponea.pushNotificationsDelegate).to(beNil())
                    expect(logger.messages.last)
                        .to(match("Cannot set push notifications delegate."))
                }
                context("Should set delegate after Exponea is configured") {
                    for configFileName in configFileNames {
                        it("Config file \(configFileName)") {
                            let exponea = ExponeaInternal()
                            exponea.configure(plistName: configFileName)
                            let delegate = MockDelegate()
                            // just initialize the notifications manager to clear the swizzling error
                            _ = exponea.notificationsManager
                            logger.messages.removeAll()
                            exponea.pushNotificationsDelegate = delegate
                            expect(exponea.pushNotificationsDelegate).to(be(delegate))
                            expect(logger.messages).to(beEmpty())
                        }
                    }
                }
            }

            context("executing with dependencies") {
                context("should complete with .success when exponea is configured") {
                    for configFileName in configFileNames {
                        it("Config file \(configFileName)") {
                            let exponea = ExponeaInternal()
                            exponea.configure(plistName: configFileName)
                            let task: ExponeaInternal.DependencyTask<String> = { _, completion in
                                completion(Result.success("success!"))
                            }
                            waitUntil(timeout: .seconds(5)) { done in
                                exponea.executeSafelyWithDependencies(task) { result in
                                    guard case .success(let data) = result else {
                                        XCTFail("Result error should be .success")
                                        done()
                                        return
                                    }
                                    expect(data).to(equal("success!"))
                                    done()
                                }
                            }
                        }
                    }
                }

                context("should complete with .failure when tasks throws an error") {
                    for configFileName in configFileNames {
                        it("Config file \(configFileName)") {
                            let exponea = ExponeaInternal()
                            exponea.configure(plistName: configFileName)
                            enum MyError: Error {
                                case someError(message: String)
                            }
                            let task: ExponeaInternal.DependencyTask<String> = { _, _ in
                                throw MyError.someError(message: "something went wrong")
                            }
                            waitUntil(timeout: .seconds(5)) { done in
                                exponea.executeSafelyWithDependencies(task) { result in
                                    guard case .failure = result else {
                                        XCTFail("Result error should be .failure")
                                        done()
                                        return
                                    }
                                    guard let error = result.error as? MyError, case .someError = error else {
                                        XCTFail("Result error should be .someError")
                                        done()
                                        return
                                    }
                                    done()
                                }
                            }
                        }
                    }
                }

                context("should complete with .failure when tasks raises NSException in safe mode") {
                    for configFileName in configFileNames {
                        it("Config file \(configFileName)") {
                            let exponea = ExponeaInternal()
                            exponea.safeModeEnabled = true
                            exponea.configure(plistName: configFileName)
                            let task: ExponeaInternal.DependencyTask<String> = { _, _ in
                                NSException(
                                    name: NSExceptionName(rawValue: "mock exception name"),
                                    reason: "mock reason",
                                    userInfo: nil
                                ).raise()
                            }
                            waitUntil(timeout: .seconds(5)) { done in
                                exponea.executeSafelyWithDependencies(task) { result in
                                    guard case .failure = result else {
                                        XCTFail("Result error should be .failure")
                                        done()
                                        return
                                    }
                                    guard let error = result.error as? ExponeaError, case .nsExceptionRaised = error else {
                                        XCTFail("Result error should be .nsExceptionRaised")
                                        done()
                                        return
                                    }
                                    done()
                                }
                            }
                        }
                    }
                }

                context("should complete any task with .failure after NSException was raised in safe mode") {
                    for configFileName in configFileNames {
                        it("Config file \(configFileName)") {
                            let exponea = ExponeaInternal()
                            exponea.safeModeEnabled = true
                            exponea.configure(plistName: configFileName)
                            let task: ExponeaInternal.DependencyTask<String> = { _, _ in
                                NSException(
                                    name: NSExceptionName(rawValue: "mock exception name"),
                                    reason: "mock reason",
                                    userInfo: nil
                                ).raise()
                            }
                            waitUntil(timeout: .seconds(5)) { done in
                                exponea.executeSafelyWithDependencies(task) { _ in done() }
                            }
                            let nextTask: ExponeaInternal.DependencyTask<String> = { _, completion in
                                completion(Result.success("success!"))
                            }
                            waitUntil(timeout: .seconds(5)) { done in
                                exponea.executeSafelyWithDependencies(nextTask) { result in
                                    guard case .failure = result else {
                                        XCTFail("Result should be a failure")
                                        done()
                                        return
                                    }
                                    guard let error = result.error as? ExponeaError,
                                          case .nsExceptionInconsistency = error else {
                                        XCTFail("Result error should be .nsExceptionInconsistency")
                                        done()
                                        return
                                    }
                                    done()
                                }
                            }
                        }
                    }
                }

                context("should re-raise NSException when not in safe mode") {
                    for configFileName in configFileNames {
                        it("Config file \(configFileName)") {
                            let exponea = ExponeaInternal()
                            exponea.safeModeEnabled = false
                            exponea.configure(plistName: configFileName)
                            let task: ExponeaInternal.DependencyTask<String> = { _, _ in
                                NSException(
                                    name: NSExceptionName(rawValue: "mock exception name"),
                                    reason: "mock reason",
                                    userInfo: nil
                                ).raise()
                            }
                            waitUntil(timeout: .seconds(5)) { done in
                                let exception = objc_tryCatch {
                                    exponea.executeSafelyWithDependencies(task) { _ in }
                                }
                                guard exception != nil else {
                                    XCTFail("No exception raised")
                                    return
                                }
                                expect(exception?.reason).to(equal("mock reason"))
                                done()
                            }
                        }
                    }
                }
            }

            context("getting customer cookie") {
                it("should return nil before the SDK is configured") {
                    let exponea = ExponeaInternal()
                    expect(exponea.customerCookie).to(beNil())
                }
                context("should return customer cookie after SDK is configured") {
                    for configFileName in configFileNames {
                        it("Config file \(configFileName)") {
                            let exponea = ExponeaInternal()
                            exponea.configure(plistName: configFileName)
                            expect(exponea.customerCookie).notTo(beNil())
                        }
                    }
                }
                context("should return new customer cookie after anonymizing") {
                    for configFileName in configFileNames {
                        it("Config file \(configFileName)") {
                            let exponea = ExponeaInternal()
                            exponea.configure(plistName: configFileName)
                            let cookie1 = exponea.customerCookie
                            exponea.anonymize()
                            let cookie2 = exponea.customerCookie
                            expect(cookie1).notTo(beNil())
                            expect(cookie2).notTo(beNil())
                            expect(cookie1).notTo(equal(cookie2))
                        }
                    }
                }
            }

            context("anonymizing") {
                // TODO: it seems that following functions are unused. Remove them if they are not needed.
                func checkEvent(event: TrackEventProxy, eventType: String, projectToken: String, userId: UUID) {
                    expect(event.eventType).to(equal(eventType))
                    expect(event.customerIds["cookie"]).to(equal(userId.uuidString))
                    expect(event.integrationId).to(equal(projectToken))
                }

                func checkCustomer(event: TrackEventProxy, eventType: String, projectToken: String, userId: UUID) {
                    expect(event.eventType).to(equal(eventType))
                    expect(event.customerIds["cookie"]).to(equal(userId.uuidString))
                    expect(event.integrationId).to(equal(projectToken))
                }

                context("should anonymize user and switch projects") {
                    it("Config: deprecated - projectToken") {
                        let database = try! DatabaseManager()
                        try! database.clear()

                        let firstCustomer = database.currentCustomer
                        Exponea.shared.userDefaults.set("device-id", forKey: Constants.General.telemetryInstallId)
                        let exponea = ExponeaInternal()
                        Exponea.shared = exponea
                        Exponea.shared.configure(
                            Exponea.ProjectSettings(projectToken: "mock-token", authorization: .token("mock-token")),
                            pushNotificationTracking: .disabled,
                            flushingSetup: Exponea.FlushingSetup(mode: .manual)
                        )

                        Exponea.shared.trackPushToken("token")
                        Exponea.shared.trackEvent(properties: [:], timestamp: nil, eventType: "test")
                        Exponea.shared.anonymize(
                            exponeaProject: ExponeaProject(
                                projectToken: "other-mock-token",
                                authorization: .token("other-mock-token")
                            ),
                            projectMapping: nil
                        )
                        let secondCustomer = database.currentCustomer

                        let events = try! database.fetchTrackEvent()
                        expect(events.count).to(equal(8))
                        expect(events[0].eventType).to(equal("installation"))
                        expect(events[0].customerIds["cookie"]).to(equal(firstCustomer.uuid.uuidString))
                        expect(events[0].integrationId).to(equal("mock-token"))

                        expect(events[1].eventType).to(equal("notification_state"))
                        expect(events[1].customerIds["cookie"]).to(equal(firstCustomer.uuid.uuidString))
                        expect(events[1].integrationId).to(equal("mock-token"))

                        expect(events[2].eventType).to(equal("test"))
                        expect(events[2].customerIds["cookie"]).to(equal(firstCustomer.uuid.uuidString))
                        expect(events[2].integrationId).to(equal("mock-token"))

                        expect(events[3].eventType).to(equal("session_end"))
                        expect(events[3].customerIds["cookie"]).to(equal(firstCustomer.uuid.uuidString))
                        expect(events[3].integrationId).to(equal("mock-token"))

                        expect(events[4].eventType).to(equal("notification_state"))
                        expect(events[4].customerIds["cookie"]).to(equal(firstCustomer.uuid.uuidString))
                        expect(events[4].integrationId).to(equal("mock-token"))

                        expect(events[5].eventType).to(equal("notification_state"))
                        expect(events[5].customerIds["cookie"]).to(equal(secondCustomer.uuid.uuidString))
                        expect(events[5].integrationId).to(equal("other-mock-token"))

                        expect(events[6].eventType).to(equal("installation"))
                        expect(events[6].customerIds["cookie"]).to(equal(secondCustomer.uuid.uuidString))
                        expect(events[6].integrationId).to(equal("other-mock-token"))

                        expect(events[7].eventType).to(equal("session_start"))
                        expect(events[7].customerIds["cookie"]).to(equal(secondCustomer.uuid.uuidString))
                        expect(events[7].integrationId).to(equal("other-mock-token"))

                        let customerUpdates = try! database.fetchTrackCustomer()
                        expect(customerUpdates.count).to(equal(3))
                        expect(customerUpdates[0].customerIds["cookie"]).to(equal(firstCustomer.uuid.uuidString))
                        expect(customerUpdates[0].dataTypes).to(equal([.properties([:])]))
                        expect(customerUpdates[0].integrationId).to(equal("mock-token"))

                        expect(customerUpdates[1].customerIds["cookie"]).to(equal(firstCustomer.uuid.uuidString))
                        expect(customerUpdates[1].dataTypes).to(equal([.properties([:])]))
                        expect(customerUpdates[1].integrationId).to(equal("mock-token"))

                        expect(customerUpdates[2].customerIds["cookie"]).to(equal(secondCustomer.uuid.uuidString))
                        expect(customerUpdates[2].dataTypes).to(equal([.properties([:])]))
                        expect(customerUpdates[2].integrationId).to(equal("other-mock-token"))
                    }
                    it("Config: integrationConfig - projectToken") {
                        let database = try! DatabaseManager()
                        try! database.clear()

                        let firstCustomer = database.currentCustomer
                        Exponea.shared.userDefaults.set("device-id", forKey: "EXPONEA_TELEMETRY_INSTALL_ID")
                        let exponea = ExponeaInternal()
                        Exponea.shared = exponea
                        Exponea.shared.configure(
                            Exponea.ProjectSettings(projectToken: "mock-token", authorization: .token("mock-token")),
                            pushNotificationTracking: .disabled,
                            flushingSetup: Exponea.FlushingSetup(mode: .manual)
                        )

                        Exponea.shared.trackPushToken("token")
                        Exponea.shared.trackEvent(properties: [:], timestamp: nil, eventType: "test")
                        Exponea.shared.anonymize(
                            exponeaIntegrationType: ExponeaProject(
                                projectToken: "other-mock-token",
                                authorization: .token("other-mock-token")
                            ),
                            exponeaProjectMapping: nil
                        )
                        let secondCustomer = database.currentCustomer

                        let events = try! database.fetchTrackEvent()
                        expect(events.count).to(equal(8))
                        expect(events[0].eventType).to(equal("installation"))
                        expect(events[0].customerIds["cookie"]).to(equal(firstCustomer.uuid.uuidString))
                        expect(events[0].integrationId).to(equal("mock-token"))

                        expect(events[1].eventType).to(equal("notification_state"))
                        expect(events[1].customerIds["cookie"]).to(equal(firstCustomer.uuid.uuidString))
                        expect(events[1].integrationId).to(equal("mock-token"))

                        expect(events[2].eventType).to(equal("test"))
                        expect(events[2].customerIds["cookie"]).to(equal(firstCustomer.uuid.uuidString))
                        expect(events[2].integrationId).to(equal("mock-token"))

                        expect(events[3].eventType).to(equal("session_end"))
                        expect(events[3].customerIds["cookie"]).to(equal(firstCustomer.uuid.uuidString))
                        expect(events[3].integrationId).to(equal("mock-token"))

                        expect(events[4].eventType).to(equal("notification_state"))
                        expect(events[4].customerIds["cookie"]).to(equal(firstCustomer.uuid.uuidString))
                        expect(events[4].integrationId).to(equal("mock-token"))

                        expect(events[5].eventType).to(equal("notification_state"))
                        expect(events[5].customerIds["cookie"]).to(equal(secondCustomer.uuid.uuidString))
                        expect(events[5].integrationId).to(equal("other-mock-token"))

                        expect(events[6].eventType).to(equal("installation"))
                        expect(events[6].customerIds["cookie"]).to(equal(secondCustomer.uuid.uuidString))
                        expect(events[6].integrationId).to(equal("other-mock-token"))

                        expect(events[7].eventType).to(equal("session_start"))
                        expect(events[7].customerIds["cookie"]).to(equal(secondCustomer.uuid.uuidString))
                        expect(events[7].integrationId).to(equal("other-mock-token"))

                        let customerUpdates = try! database.fetchTrackCustomer()
                        expect(customerUpdates.count).to(equal(3))
                        expect(customerUpdates[0].customerIds["cookie"]).to(equal(firstCustomer.uuid.uuidString))
                        expect(customerUpdates[0].dataTypes).to(equal([.properties([:])]))
                        expect(customerUpdates[0].integrationId).to(equal("mock-token"))

                        expect(customerUpdates[1].customerIds["cookie"]).to(equal(firstCustomer.uuid.uuidString))
                        expect(customerUpdates[1].dataTypes).to(equal([.properties([:])]))
                        expect(customerUpdates[1].integrationId).to(equal("mock-token"))

                        expect(customerUpdates[2].customerIds["cookie"]).to(equal(secondCustomer.uuid.uuidString))
                        expect(customerUpdates[2].dataTypes).to(equal([.properties([:])]))
                        expect(customerUpdates[2].integrationId).to(equal("other-mock-token"))
                    }
                    it("Config: integrationConfig - streamId") {
                        let database = try! DatabaseManager()
                        try! database.clear()

                        let firstCustomer = database.currentCustomer
                        Exponea.shared.userDefaults.set("device-id", forKey: "EXPONEA_TELEMETRY_INSTALL_ID")
                        let exponea = ExponeaInternal()
                        Exponea.shared = exponea
                        Exponea.shared.configure(
                            Exponea.StreamSettings(streamId: "mock-token"),
                            pushNotificationTracking: .disabled,
                            flushingSetup: Exponea.FlushingSetup(mode: .manual)
                        )

                        Exponea.shared.trackPushToken("token")
                        Exponea.shared.trackEvent(properties: [:], timestamp: nil, eventType: "test")
                        Exponea.shared.anonymize(
                            exponeaIntegrationType: ExponeaIntegration(
                                streamId: "other-mock-token"
                            ),
                            exponeaProjectMapping: nil
                        )
                        let secondCustomer = database.currentCustomer

                        let events = try! database.fetchTrackEvent()
                        expect(events.count).to(equal(8))
                        expect(events[0].eventType).to(equal("installation"))
                        expect(events[0].customerIds["cookie"]).to(equal(firstCustomer.uuid.uuidString))
                        expect(events[0].integrationId).to(equal("mock-token"))

                        expect(events[1].eventType).to(equal("notification_state"))
                        expect(events[1].customerIds["cookie"]).to(equal(firstCustomer.uuid.uuidString))
                        expect(events[1].integrationId).to(equal("mock-token"))

                        expect(events[2].eventType).to(equal("test"))
                        expect(events[2].customerIds["cookie"]).to(equal(firstCustomer.uuid.uuidString))
                        expect(events[2].integrationId).to(equal("mock-token"))

                        expect(events[3].eventType).to(equal("session_end"))
                        expect(events[3].customerIds["cookie"]).to(equal(firstCustomer.uuid.uuidString))
                        expect(events[3].integrationId).to(equal("mock-token"))

                        expect(events[4].eventType).to(equal("notification_state"))
                        expect(events[4].customerIds["cookie"]).to(equal(firstCustomer.uuid.uuidString))
                        expect(events[4].integrationId).to(equal("mock-token"))

                        expect(events[5].eventType).to(equal("notification_state"))
                        expect(events[5].customerIds["cookie"]).to(equal(secondCustomer.uuid.uuidString))
                        expect(events[5].integrationId).to(equal("other-mock-token"))

                        expect(events[6].eventType).to(equal("installation"))
                        expect(events[6].customerIds["cookie"]).to(equal(secondCustomer.uuid.uuidString))
                        expect(events[6].integrationId).to(equal("other-mock-token"))

                        expect(events[7].eventType).to(equal("session_start"))
                        expect(events[7].customerIds["cookie"]).to(equal(secondCustomer.uuid.uuidString))
                        expect(events[7].integrationId).to(equal("other-mock-token"))

                        let customerUpdates = try! database.fetchTrackCustomer()
                        expect(customerUpdates.count).to(equal(3))
                        expect(customerUpdates[0].customerIds["cookie"]).to(equal(firstCustomer.uuid.uuidString))
                        expect(customerUpdates[0].dataTypes).to(equal([.properties([:])]))
                        expect(customerUpdates[0].integrationId).to(equal("mock-token"))

                        expect(customerUpdates[1].customerIds["cookie"]).to(equal(firstCustomer.uuid.uuidString))
                        expect(customerUpdates[1].dataTypes).to(equal([.properties([:])]))
                        expect(customerUpdates[1].integrationId).to(equal("mock-token"))

                        expect(customerUpdates[2].customerIds["cookie"]).to(equal(secondCustomer.uuid.uuidString))
                        expect(customerUpdates[2].dataTypes).to(equal([.properties([:])]))
                        expect(customerUpdates[2].integrationId).to(equal("other-mock-token"))
                    }
                }

                context("should switch projects with anonymize and store them localy") {
                    it("Config: deprecated - projectToken") {
                        let appGroup = "MockAppGroup"
                        let exponea = ExponeaInternal()
                        Exponea.shared = exponea
                        Exponea.shared.configure(
                            Exponea.ProjectSettings(projectToken: "mock-token", authorization: .token("mock-token")),
                            pushNotificationTracking: .enabled(appGroup: appGroup),
                            flushingSetup: Exponea.FlushingSetup(mode: .manual)
                        )
                        guard let configuration = Configuration.loadFromUserDefaults(appGroup: appGroup) else {
                            fail("Configuration has not been loaded for \(appGroup)")
                            return
                        }
                        expect(configuration.projectToken).to(equal("mock-token"))
                        expect(configuration.authorization).to(equal(.token("mock-token")))
                        Exponea.shared.anonymize(
                            exponeaProject: ExponeaProject(
                                projectToken: "other-mock-token",
                                authorization: .token("other-mock-token")
                            ),
                            projectMapping: nil
                        )
                        guard let configurationAfterAnonymize = Configuration.loadFromUserDefaults(appGroup: appGroup) else {
                            fail("Configuration has not been loaded after anonymize for \(appGroup)")
                            return
                        }
                        expect(configurationAfterAnonymize.projectToken).to(equal("other-mock-token"))
                        expect(configurationAfterAnonymize.authorization).to(equal(.token("other-mock-token")))
                    }
                    
                    it("Config: integrationConfig - projectToken") {
                        let appGroup = "MockAppGroup"
                        let exponea = ExponeaInternal()
                        Exponea.shared = exponea
                        Exponea.shared.configure(
                            Exponea.ProjectSettings(projectToken: "mock-token", authorization: .token("mock-token")),
                            pushNotificationTracking: .enabled(appGroup: appGroup),
                            flushingSetup: Exponea.FlushingSetup(mode: .manual)
                        )
                        guard let configuration = Configuration.loadFromUserDefaults(appGroup: appGroup) else {
                            fail("Configuration has not been loaded for \(appGroup)")
                            return
                        }
                        expect(configuration.integrationId).to(equal("mock-token"))
                        expect((configuration.integrationConfig as? Exponea.ProjectSettings)?.authorization).to(equal(.token("mock-token")))
                        
                        Exponea.shared.anonymize(
                            exponeaIntegrationType: ExponeaProject(
                                projectToken: "other-mock-token",
                                authorization: .token("other-mock-token")
                            ),
                            exponeaProjectMapping: nil
                        )
                        guard let configurationAfterAnonymize = Configuration.loadFromUserDefaults(appGroup: appGroup) else {
                            fail("Configuration has not been loaded after anonymize for \(appGroup)")
                            return
                        }
                        expect(configurationAfterAnonymize.integrationId).to(equal("other-mock-token"))
                        expect((configurationAfterAnonymize.integrationConfig as? Exponea.ProjectSettings)?.authorization).to(equal(.token("other-mock-token")))
                    }
                    
                    it("Config: integrationConfig - streamId") {
                        let appGroup = "MockAppGroup"
                        let exponea = ExponeaInternal()
                        Exponea.shared = exponea
                        Exponea.shared.configure(
                            Exponea.StreamSettings(streamId: "mock-token"),
                            pushNotificationTracking: .enabled(appGroup: appGroup),
                            flushingSetup: Exponea.FlushingSetup(mode: .manual)
                        )
                        guard let configuration = Configuration.loadFromUserDefaults(appGroup: appGroup) else {
                            fail("Configuration has not been loaded for \(appGroup)")
                            return
                        }
                        expect(configuration.integrationId).to(equal("mock-token"))
                        
                        Exponea.shared.anonymize(
                            exponeaIntegrationType: ExponeaIntegration(
                                streamId: "other-mock-token"
                            ),
                            exponeaProjectMapping: nil
                        )
                        guard let configurationAfterAnonymize = Configuration.loadFromUserDefaults(appGroup: appGroup) else {
                            fail("Configuration has not been loaded after anonymize for \(appGroup)")
                            return
                        }
                        expect(configurationAfterAnonymize.integrationId).to(equal("other-mock-token"))
                    }
                }
            }
        }
    }
}
