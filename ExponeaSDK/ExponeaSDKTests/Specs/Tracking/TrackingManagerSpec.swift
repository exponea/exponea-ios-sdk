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
import Mockingjay

@testable import ExponeaSDK

class TrackingManagerSpec: QuickSpec {
    override func spec() {
        _ = MockUserNotificationCenter.shared
        describe("TrackingManager") {
            var trackingManager: TrackingManager!
            var repository: RepositoryType!
            var database: DatabaseManagerType!
            var userDefaults: UserDefaults!

            beforeEach {
                var configuration = try! Configuration(
                    projectToken: "mock-project-token",
                    authorization: .token("mock-token"),
                    baseUrl: "https://google.com" // has to be real url because of reachability
                )
                configuration.automaticSessionTracking = false
                configuration.flushEventMaxRetries = 5
                repository = ServerRepository(configuration: configuration)
                database = try! MockDatabaseManager()
                userDefaults = MockUserDefaults()

                // Mark install event as already tracked
                // - otherwise it's automatically tracked with immediate flushing, which makes testing difficult
                let key = Constants.Keys.installTracked + (database.customer.uuid?.uuidString ?? "")
                userDefaults.set(true, forKey: key)

                trackingManager = TrackingManager(
                    repository: repository,
                    database: database,
                    userDefaults: userDefaults
                )

                trackingManager.flushingMode = .manual
            }

            afterEach {
                self.unstubNetwork()
            }

            it("should track event into database") {
                let data: [DataType] = [.projectToken(MockData().projectToken),
                                        .properties(MockData().properties)]
                expect { try trackingManager.trackEvent(with: data) }.notTo(raiseException())
                expect { try database.fetchTrackEvent().count }.to(equal(1))
            }

            it("should only allow one thread to flush") {
                let data: [DataType] = [.projectToken(MockData().projectToken),
                                        .properties(MockData().properties)]
                expect { try trackingManager.trackEvent(with: data) }.notTo(raiseException())

                var networkRequests: Int = 0
                self.stubNetwork(withStatusCode: 200, withRequestHook: { _ in networkRequests += 1})

                waitUntil() { done in
                    let group = DispatchGroup()
                    for _ in 0..<10 {
                        group.enter()
                        DispatchQueue.global(qos: .background).async {
                            trackingManager.flushData(completion: {group.leave()})
                        }
                    }
                    group.notify(queue: .main, execute: done)
                }

                expect(networkRequests).to(equal(1))
            }

            it("should flush event") {
                let data: [DataType] = [.projectToken(MockData().projectToken),
                                        .properties(MockData().properties)]
                expect { try trackingManager.trackEvent(with: data) }.notTo(raiseException())
                expect { try database.fetchTrackEvent().count }.to(equal(1))
                self.stubNetwork(withStatusCode: 200)
                waitUntil() { done in
                    trackingManager.flushData(completion: {done()})
                }
                expect { try database.fetchTrackEvent().count }.to(equal(0))
            }

            it("should retry flushing event `configuration.flushEventMaxRetries` times on weird errors") {
                let data: [DataType] = [.projectToken(MockData().projectToken),
                                        .properties(MockData().properties)]
                expect { try trackingManager.trackEvent(with: data) }.notTo(raiseException())
                expect { try database.fetchTrackEvent().count }.to(equal(1))
                self.stubNetwork(withStatusCode: 418)
                for i in 1...4 {
                    waitUntil() { done in
                        trackingManager.flushData(completion: {done()})
                    }
                    expect { try database.fetchTrackEvent().count }.to(equal(1))
                    expect { try database.fetchTrackEvent().first?.retries }.to(equal(i))
                }
                waitUntil() { done in
                    trackingManager.flushData(completion: {done()})
                }
                expect { try database.fetchTrackEvent().count }.to(equal(0))
            }

            it("should retry flushing event forever on 500 errors") {
                let data: [DataType] = [.projectToken(MockData().projectToken),
                                        .properties(MockData().properties)]
                expect { try trackingManager.trackEvent(with: data) }.notTo(raiseException())
                expect { try database.fetchTrackEvent().count }.to(equal(1))
                self.stubNetwork(withStatusCode: 500)
                for _ in 1...10 {
                    waitUntil() { done in
                        trackingManager.flushData(completion: {done()})
                    }
                    expect { try database.fetchTrackEvent().count }.to(equal(1))
                }
            }

            context("updateLastEvent") {
                var trackingManager: TrackingManager!

                beforeEach {
                    let configuration = try! Configuration(plistName: "TrackingManagerUpdate")
                    let repo = ServerRepository(configuration: configuration)
                    let database = try! MockDatabaseManager()

                    trackingManager = TrackingManager(repository: repo,
                                                      database: database,
                                                      userDefaults: UserDefaults())
                    self.stubNetwork(withStatusCode: 200)
                }

                afterEach {
                    self.unstubNetwork()
                }

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
                    let event = try! trackingManager.database.fetchTrackEvent().first!
                    expect { event.properties?["testkey"]?.rawValue as? String }.to(equal("testvalue"))
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
                    let events = try! trackingManager.database.fetchTrackEvent()
                    events.forEach { event in
                        if event.eventType == Constants.EventTypes.sessionEnd {
                            let order = event.properties?["order"]?.rawValue as? String
                            let insertedData = event.properties?["testkey"]?.rawValue as? String
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
                    let events = try! trackingManager.database.fetchTrackEvent()
                    events.forEach { event in
                        if event.eventType == Constants.EventTypes.sessionStart {
                            if event.eventType == Constants.EventTypes.sessionEnd {
                                let order = event.properties?["order"]?.rawValue as? String
                                let insertedData = event.properties?["testkey"]?.rawValue as? String
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
        }
    }

    func stubNetwork(withStatusCode statusCode: Int, withRequestHook requestHook: ((URLRequest) -> Void)? = nil) {
        let stubResponse = HTTPURLResponse(url: URL(string: "mock-url")!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        let stubData = "mock-response".data(using: String.Encoding.utf8, allowLossyConversion: true)!
        MockingjayProtocol.addStub(matcher: { request in return true }) { (request) -> (Response) in
            requestHook?(request)
            return Response.success(stubResponse, .content(stubData))
        }
    }

    func unstubNetwork() {
        MockingjayProtocol.removeAllStubs()
    }
}
