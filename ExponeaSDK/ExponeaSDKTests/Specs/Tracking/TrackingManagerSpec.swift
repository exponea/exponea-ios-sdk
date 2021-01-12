//
//  TrackEventSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 13/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Nimble
import Mockingjay
import Quick

@testable import ExponeaSDK
@testable import ExponeaSDKShared

class TrackingManagerSpec: QuickSpec {
    override func spec() {
        describe("TrackingManager") {
            var trackingManager: TrackingManager!
            var repository: RepositoryType!
            var database: DatabaseManagerType!
            var userDefaults: UserDefaults!
            var configuration: ExponeaSDK.Configuration!

            beforeEach {
                configuration = try! Configuration(
                    projectToken: UUID().uuidString,
                    authorization: .token("mock-token"),
                    baseUrl: "https://google.com", // has to be real url because of reachability
                    defaultProperties: ["default_prop": "default_value"]
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
                    inAppMessagesManager: MockInAppMessagesManager(),
                    userDefaults: userDefaults
                )
            }

            afterEach {
                NetworkStubbing.unstubNetwork()
            }

            it("should track event into database") {
                let data: [DataType] = [.properties(MockData().properties)]
                expect { try trackingManager.track(EventType.customEvent, with: data) }.notTo(raiseException())
                expect { try database.fetchTrackEvent().count }.to(equal(1))
            }

            it("should add default properties to event with properties") {
                let data: [DataType] = [
                    .properties(["prop": .string("value")]),
                    .timestamp(123456)
                ]
                expect { try trackingManager.track(EventType.customEvent, with: data) }.notTo(raiseException())
                expect { try database.fetchTrackEvent()[0].dataTypes }.to(equal([
                    .properties(["prop": .string("value"), "default_prop": .string("default_value")]),
                    .timestamp(123456)
                ]))
            }

            it("should add default properties to event without properties") {
                let data: [DataType] = [.timestamp(123456)]
                expect { try trackingManager.track(EventType.customEvent, with: data) }.notTo(raiseException())
                expect { try database.fetchTrackEvent()[0].dataTypes }.to(equal([
                    .properties(["default_prop": .string("default_value")]),
                    .timestamp(123456)
                ]))
            }

            context("updateLastEvent") {
                it("should do nothing without events") {
                    let updateData = DataType.properties(["testkey": .string("testvalue")])
                    expect {
                        try trackingManager.updateLastPendingEvent(ofType: Constants.EventTypes.sessionStart,
                                                            with: updateData)
                    }.notTo(raiseException())
                }

                it("should update event") {
                    let updateData = DataType.properties(["testkey": .string("testvalue")])
                    expect {
                        try trackingManager.track(EventType.sessionEnd, with: [])
                    }.notTo(raiseException())
                    expect {
                        try trackingManager.updateLastPendingEvent(ofType: Constants.EventTypes.sessionEnd,
                                                            with: updateData)
                    }.notTo(raiseException())
                    let trackEvent = try! trackingManager.database.fetchTrackEvent().first!
                    expect { trackEvent.dataTypes.properties["testkey"] as? String }.to(equal("testvalue"))
                }

                it("should only update last event") {
                    let updateData = DataType.properties(["testkey": .string("testvalue")])
                    expect {
                        try trackingManager.track(EventType.sessionEnd,
                                                  with: [DataType.properties(["order": .string("1")])])
                    }.notTo(raiseException())
                    expect {
                        try trackingManager.track(EventType.sessionEnd,
                                                  with: [DataType.properties(["order": .string("2")])])
                    }.notTo(raiseException())
                    expect {
                        try trackingManager.track(EventType.sessionEnd,
                                                  with: [DataType.properties(["order": .string("3")])])
                    }.notTo(raiseException())
                    expect {
                        try trackingManager.updateLastPendingEvent(ofType: Constants.EventTypes.sessionEnd,
                                                            with: updateData)
                    }.notTo(raiseException())
                    let trackEvents = try! trackingManager.database.fetchTrackEvent()
                    trackEvents.forEach { trackEvent in
                        if trackEvent.eventType == Constants.EventTypes.sessionEnd {
                            let order = trackEvent.dataTypes.properties["order"] as? String
                            let insertedData = trackEvent.dataTypes.properties["testkey"] as? String
                            if order == "3" {
                                expect { insertedData }.to(equal("testvalue"))
                            } else {
                                expect { insertedData }.to(beNil())
                            }
                        }
                    }
                }

                it("should update multiple events if there are multiple project tokens") {
                    let updateData = DataType.properties(["testkey": .string("testvalue")])
                    expect {
                        try trackingManager.track(EventType.sessionStart,
                                                  with: [DataType.properties(["order": .string("1")])])
                    }.notTo(raiseException())
                    expect {
                        try trackingManager.track(EventType.sessionStart,
                                                  with: [DataType.properties(["order": .string("2")])])
                    }.notTo(raiseException())
                    expect {
                        try trackingManager.track(EventType.sessionStart,
                                                  with: [DataType.properties(["order": .string("3")])])
                    }.notTo(raiseException())
                    expect {
                        try trackingManager.updateLastPendingEvent(ofType: Constants.EventTypes.sessionStart,
                                                            with: updateData)
                    }.notTo(raiseException())
                    let trackEvents = try! trackingManager.database.fetchTrackEvent()
                    trackEvents.forEach { trackEvent in
                        if trackEvent.eventType == Constants.EventTypes.sessionStart {
                            if trackEvent.eventType == Constants.EventTypes.sessionEnd {
                                let order = trackEvent.dataTypes.properties["order"] as? String
                                let insertedData = trackEvent.dataTypes.properties["testkey"] as? String
                                if order == "3" {
                                    expect { insertedData }.to(equal("testvalue"))
                                } else {
                                    expect { insertedData }.to(beNil())
                                }
                            }
                        }
                    }
                }
            }
            context("InAppMessageTrackingDelegate") {
                it("should track click in-app message event") {
                    trackingManager.track(
                        .click(buttonLabel: "mock-text"),
                        for: SampleInAppMessage.getSampleInAppMessage()
                    )
                    let trackEvents = try! trackingManager.database.fetchTrackEvent()
                    expect(trackEvents.count).to(equal(1))
                    let event = trackEvents[0]
                    expect(event.eventType).to(equal(Constants.EventTypes.banner))
                    expect(event.dataTypes.properties["banner_id"] as? String).to(equal("5dd86f44511946ea55132f29"))
                    expect(event.dataTypes.properties["banner_name"] as? String)
                        .to(equal("Test serving in-app message"))
                    expect(event.dataTypes.properties["action"] as? String).to(equal("click"))
                    expect(event.dataTypes.properties["text"] as? String).to(equal("mock-text"))
                    expect(event.dataTypes.properties["interaction"] as? Bool).to(equal(true))
                    expect(event.dataTypes.properties["variant_id"] as? Int).to(equal(0))
                    expect(event.dataTypes.properties["variant_name"] as? String).to(equal("Variant A"))
                }

                it("should track close in-app message event") {
                    trackingManager.track(
                        .close,
                        for: SampleInAppMessage.getSampleInAppMessage()
                    )
                    let trackEvents = try! trackingManager.database.fetchTrackEvent()
                    expect(trackEvents.count).to(equal(1))
                    let event = trackEvents[0]
                    expect(event.eventType).to(equal(Constants.EventTypes.banner))
                    expect(event.dataTypes.properties["banner_id"] as? String).to(equal("5dd86f44511946ea55132f29"))
                    expect(event.dataTypes.properties["banner_name"] as? String)
                        .to(equal("Test serving in-app message"))
                    expect(event.dataTypes.properties["action"] as? String).to(equal("close"))
                    expect(event.dataTypes.properties["text"] as? String).to(beNil())
                    expect(event.dataTypes.properties["interaction"] as? Bool).to(equal(false))
                    expect(event.dataTypes.properties["variant_id"] as? Int).to(equal(0))
                    expect(event.dataTypes.properties["variant_name"] as? String).to(equal("Variant A"))
                }
            }
        }
    }
}
