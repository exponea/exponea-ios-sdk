//
//  TrackManager+IdentifyCustomerSpec.swift
//  ExponeaSDKTests
//
//  Created by Adam Mihalik on 07/11/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//

import Foundation
import Nimble
import Mockingjay
import Quick

@testable import ExponeaSDK
@testable import ExponeaSDKShared

/// Tests for tracking of 'identifyCustomer' event with allowed/disabled default properties usage.
class TrackingManagerForIdentifyCustomerSpec: QuickSpec {
    override func spec() {
        describe("TrackingManager") {
            var trackingManager: TrackingManager!
            var repository: RepositoryType!
            var database: DatabaseManagerType!
            var userDefaults: UserDefaults!
            var configuration: ExponeaSDK.Configuration!
            
            func prepareEnvironment(_ allowDefaultProperties: Bool?) {
                configuration = try! Configuration(
                    projectToken: UUID().uuidString,
                    authorization: .token("mock-token"),
                    baseUrl: "https://google.com", // has to be real url because of reachability
                    defaultProperties: ["default_prop": "default_value"],
                    allowDefaultCustomerProperties: allowDefaultProperties
                )
                configuration.automaticSessionTracking = false
                configuration.flushEventMaxRetries = 5
                repository = ServerRepository(configuration: configuration)
                database = try! MockDatabaseManager()
                userDefaults = MockUserDefaults()

                // Mark install event as already tracked
                // - otherwise it's automatically tracked with immediate flushing, which makes testing difficult
                let key = Constants.Keys.installTracked + database.currentCustomer.uuid.uuidString
                userDefaults.set(true, forKey: key)

                trackingManager = try! TrackingManager(
                    repository: repository,
                    database: database,
                    flushingManager: MockFlushingManager(),
                    userDefaults: userDefaults,
                    onEventCallback: { _, _ in
                    }
                )
            }

            afterEach {
                NetworkStubbing.unstubNetwork()
            }

            it("should add default properties to track_customer by default") {
                prepareEnvironment(nil)
                let data: [DataType] = [
                    .properties(["prop": .string("value")])
                ]
                expect { try trackingManager.track(EventType.identifyCustomer, with: data) }.notTo(raiseException())
                expect { try database.fetchTrackCustomer()[0].dataTypes }.to(equal([
                    .properties(["prop": .string("value"), "default_prop": .string("default_value")])
                ]))
            }

            it("should add default properties to track_customer if allowed") {
                prepareEnvironment(true)
                let data: [DataType] = [
                    .properties(["prop": .string("value")])
                ]
                expect { try trackingManager.track(EventType.identifyCustomer, with: data) }.notTo(raiseException())
                expect { try database.fetchTrackCustomer()[0].dataTypes }.to(equal([
                    .properties(["prop": .string("value"), "default_prop": .string("default_value")])
                ]))
            }

            it("should NOT add default properties to track_customer if denied") {
                prepareEnvironment(false)
                let data: [DataType] = [
                    .properties(["prop": .string("value")])
                ]
                expect { try trackingManager.track(EventType.identifyCustomer, with: data) }.notTo(raiseException())
                expect { try database.fetchTrackCustomer()[0].dataTypes }.to(equal([
                    .properties(["prop": .string("value")])
                ]))
            }

            it("should add default properties to track push token by default") {
                prepareEnvironment(nil)
                expect {
                    try trackingManager.track(
                        EventType.registerPushToken,
                        with: [.pushNotificationToken(token: "abcd", authorized: true)]
                    )
                }.notTo(raiseException())
                expect { try database.fetchTrackCustomer()[0].dataTypes }.to(equal([
                    .properties([
                        "default_prop": .string("default_value"),
                        "apple_push_notification_authorized": .bool(true),
                        "apple_push_notification_id": .string("abcd")
                    ])
                ]))
            }

            it("should add default properties to track push token if allowed") {
                prepareEnvironment(true)
                expect {
                    try trackingManager.track(
                        EventType.registerPushToken,
                        with: [.pushNotificationToken(token: "abcd", authorized: true)]
                    )
                }.notTo(raiseException())
                expect { try database.fetchTrackCustomer()[0].dataTypes }.to(equal([
                    .properties([
                        "default_prop": .string("default_value"),
                        "apple_push_notification_authorized": .bool(true),
                        "apple_push_notification_id": .string("abcd")
                    ])
                ]))
            }

            it("should NOT add default properties to track push token if denied") {
                prepareEnvironment(false)
                expect {
                    try trackingManager.track(
                        EventType.registerPushToken,
                        with: [.pushNotificationToken(token: "abcd", authorized: true)]
                    )
                }.notTo(raiseException())
                expect { try database.fetchTrackCustomer()[0].dataTypes }.to(equal([
                    .properties([
                        "apple_push_notification_authorized": .bool(true),
                        "apple_push_notification_id": .string("abcd")
                    ])
                ]))
            }
        }
    }
}
