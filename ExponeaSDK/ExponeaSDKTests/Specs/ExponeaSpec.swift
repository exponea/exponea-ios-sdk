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
            context("Before being configured") {
                var exponea = ExponeaInternal()
                beforeEach {
                    exponea = ExponeaInternal()
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
                    expect(exponea.trackCampaignClick(url: URL(string: "mockUrl")!, timestamp: nil))
                        .notTo(raiseException())
                }
                it("Should not crash tracking payment") {
                    expect(exponea.trackPayment(properties: [:], timestamp: nil)).notTo(raiseException())
                }
                it("Should not crash identifing customer") {
                    expect(exponea.identifyCustomer(customerIds: [:], properties: [:], timestamp: nil))
                        .notTo(raiseException())
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
                    expect(exponea.configuration?.projectToken).to(equal("0aef3a96-3804-11e8-b710-141877340e97"))
                }
            }
            context("After being configured from plist file") {
                let exponea = ExponeaInternal()
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
                let exponea = ExponeaInternal()
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
                let exponea = ExponeaInternal()
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
                var logger: MockLogger!
                beforeEach {
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
                it("Should set delegate after Exponea is configured") {
                    let exponea = ExponeaInternal()
                    exponea.configure(plistName: "ExponeaConfig")
                    let delegate = MockDelegate()
                    // just initialize the notifications manager to clear the swizzling error
                    _ = exponea.trackingManager?.notificationsManager
                    logger.messages.removeAll()
                    exponea.pushNotificationsDelegate = delegate
                    expect(exponea.pushNotificationsDelegate).to(be(delegate))
                    expect(logger.messages).to(beEmpty())
                }
            }

            context("executing with dependencies") {
                it("should complete with .failure when exponea is not configured") {
                    let exponea = ExponeaInternal()
                    let task: ExponeaInternal.DependencyTask<String> = { _, completion in
                        completion(Result.success("success!"))
                    }
                    waitUntil { done in
                        exponea.executeSafelyWithDependencies(task) { result in
                            guard case .failure = result else {
                                XCTFail("Result should be a failure")
                                done()
                                return
                            }
                            guard let error = result.error as? ExponeaError, case .notConfigured = error else {
                                XCTFail("Result error should be .notConfigured")
                                done()
                                return
                            }
                            done()
                        }
                    }
                }
                it("should complete with .success when exponea is configured") {
                    let exponea = ExponeaInternal()
                    exponea.configure(plistName: "ExponeaConfig")
                    let task: ExponeaInternal.DependencyTask<String> = { _, completion in
                        completion(Result.success("success!"))
                    }
                    waitUntil { done in
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

                it("should complete with .failure when tasks throws an error") {
                    let exponea = ExponeaInternal()
                    exponea.configure(plistName: "ExponeaConfig")
                    enum MyError: Error {
                        case someError(message: String)
                    }
                    let task: ExponeaInternal.DependencyTask<String> = { _, _ in
                        throw MyError.someError(message: "something went wrong")
                    }
                    waitUntil { done in
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

                it("should complete with .failure when tasks raises NSException in safe mode") {
                    let exponea = ExponeaInternal()
                    exponea.safeModeEnabled = true
                    exponea.configure(plistName: "ExponeaConfig")
                    let task: ExponeaInternal.DependencyTask<String> = { _, _ in
                        NSException(
                            name: NSExceptionName(rawValue: "mock exception name"),
                            reason: "mock reason",
                            userInfo: nil
                        ).raise()
                    }
                    waitUntil { done in
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

                it("should complete any task with .failure after NSException was raised in safe mode") {
                    let exponea = ExponeaInternal()
                    exponea.safeModeEnabled = true
                    exponea.configure(plistName: "ExponeaConfig")
                    let task: ExponeaInternal.DependencyTask<String> = { _, _ in
                        NSException(
                            name: NSExceptionName(rawValue: "mock exception name"),
                            reason: "mock reason",
                            userInfo: nil
                        ).raise()
                    }
                    waitUntil { done in
                        exponea.executeSafelyWithDependencies(task) { _ in done() }
                    }
                    let nextTask: ExponeaInternal.DependencyTask<String> = { _, completion in
                        completion(Result.success("success!"))
                    }
                    waitUntil { done in
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

                it("should re-raise NSException when not in safe mode") {
                    let exponea = ExponeaInternal()
                    exponea.safeModeEnabled = false
                    exponea.configure(plistName: "ExponeaConfig")
                    let task: ExponeaInternal.DependencyTask<String> = { _, _ in
                        NSException(
                            name: NSExceptionName(rawValue: "mock exception name"),
                            reason: "mock reason",
                            userInfo: nil
                        ).raise()
                    }
                    waitUntil { done in
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

            context("getting customer cookie") {
                it("should return nil before the SDK is configured") {
                    let exponea = ExponeaInternal()
                    expect(exponea.customerCookie).to(beNil())
                }
                it("should return customer cookie after SDK is configured") {
                    let exponea = ExponeaInternal()
                    exponea.configure(plistName: "ExponeaConfig")
                    expect(exponea.customerCookie).notTo(beNil())
                }
                it("should return new customer cookie after anonymizing") {
                    let exponea = ExponeaInternal()
                    exponea.configure(plistName: "ExponeaConfig")
                    let cookie1 = exponea.customerCookie
                    exponea.anonymize()
                    let cookie2 = exponea.customerCookie
                    expect(cookie1).notTo(beNil())
                    expect(cookie2).notTo(beNil())
                    expect(cookie1).notTo(equal(cookie2))
                }
            }

            context("anonymizing") {
                func checkEvent(event: TrackEventProxy, eventType: String, projectToken: String, userId: UUID) {
                    expect(event.eventType).to(equal(eventType))
                    expect(event.customerIds["cookie"]).to(equal(userId.uuidString))
                    expect(event.projectToken).to(equal(projectToken))
                }

                func checkCustomer(event: TrackEventProxy, eventType: String, projectToken: String, userId: UUID) {
                    expect(event.eventType).to(equal(eventType))
                    expect(event.customerIds["cookie"]).to(equal(userId.uuidString))
                    expect(event.projectToken).to(equal(projectToken))
                }

                it("should anonymize user and switch projects") {
                    let database = try! DatabaseManager()
                    try! database.clear()

                    let firstCustomer = database.currentCustomer
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
                    expect(events.count).to(equal(4))
                    expect(events[0].eventType).to(equal("installation"))
                    expect(events[0].customerIds["cookie"]).to(equal(firstCustomer.uuid.uuidString))
                    expect(events[0].projectToken).to(equal("mock-token"))

                    expect(events[1].eventType).to(equal("test"))
                    expect(events[1].customerIds["cookie"]).to(equal(firstCustomer.uuid.uuidString))
                    expect(events[1].projectToken).to(equal("mock-token"))

                    expect(events[2].eventType).to(equal("installation"))
                    expect(events[2].customerIds["cookie"]).to(equal(secondCustomer.uuid.uuidString))
                    expect(events[2].projectToken).to(equal("other-mock-token"))

                    expect(events[3].eventType).to(equal("session_start"))
                    expect(events[3].customerIds["cookie"]).to(equal(secondCustomer.uuid.uuidString))
                    expect(events[3].projectToken).to(equal("other-mock-token"))

                    let customerUpdates = try! database.fetchTrackCustomer()
                    expect(customerUpdates.count).to(equal(3))
                    expect(customerUpdates[0].customerIds["cookie"]).to(equal(firstCustomer.uuid.uuidString))
                    expect(customerUpdates[0].dataTypes)
                        .to(equal([.properties([
                            "apple_push_notification_authorized": .bool(true),
                            "apple_push_notification_id": .string("token")
                        ])]))
                    expect(customerUpdates[0].projectToken).to(equal("mock-token"))

                    expect(customerUpdates[1].customerIds["cookie"]).to(equal(firstCustomer.uuid.uuidString))
                    expect(customerUpdates[1].dataTypes)
                        .to(equal([.properties([
                            "apple_push_notification_authorized": .bool(false),
                            "apple_push_notification_id": .string("")
                        ])]))
                    expect(customerUpdates[1].projectToken).to(equal("mock-token"))

                    expect(customerUpdates[2].customerIds["cookie"]).to(equal(secondCustomer.uuid.uuidString))
                    expect(customerUpdates[2].dataTypes)
                        .to(equal([.properties([
                            "apple_push_notification_authorized": .bool(true),
                            "apple_push_notification_id": .string("token")
                        ])]))
                    expect(customerUpdates[2].projectToken).to(equal("other-mock-token"))
                }
            }
        }
    }
}
