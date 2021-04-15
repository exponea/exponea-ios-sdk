//
//  FlushingManagerSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 13/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation
import Nimble
import Mockingjay
import Quick

@testable import ExponeaSDK
@testable import ExponeaSDKShared

class FlushingManagerSpec: QuickSpec {
    override func spec() {
        describe("FlushingManager") {
            var flushingManager: FlushingManager!
            var repository: RepositoryType!
            var database: MockDatabaseManager!
            var configuration: ExponeaSDK.Configuration!

            var eventData: [DataType]!

            beforeEach {
                configuration = try! Configuration(
                    projectToken: UUID().uuidString,
                    authorization: .token("mock-token"),
                    baseUrl: "https://google.com" // has to be real url because of reachability
                )
                configuration.automaticSessionTracking = false
                configuration.flushEventMaxRetries = 5
                repository = ServerRepository(configuration: configuration)
                database = try! MockDatabaseManager()

                flushingManager = try! FlushingManager(
                    database: database,
                    repository: repository,
                    customerIdentifiedHandler: {}
                )

                eventData = [.properties(MockData().properties)]
            }

            afterEach {
                NetworkStubbing.unstubNetwork()
            }

            it("should only allow one thread to flush") {
                try! database.trackEvent(with: eventData, into: configuration.mainProject)

                var networkRequests: Int = 0
                NetworkStubbing.stubNetwork(
                    forProjectToken: configuration.projectToken,
                    withStatusCode: 200,
                    withRequestHook: { _ in networkRequests += 1 }
                )

                waitUntil(timeout: .seconds(3)) { done in
                    let group = DispatchGroup()
                    for _ in 0..<10 {
                        group.enter()
                        DispatchQueue.global(qos: .background).async {
                            flushingManager.flushData(completion: { _ in group.leave() })
                        }
                    }
                    group.notify(queue: .main, execute: done)
                }

                expect(networkRequests).to(equal(1))
            }

            it("should flush event") {
                try! database.trackEvent(with: eventData, into: configuration.mainProject)
                NetworkStubbing.stubNetwork(forProjectToken: configuration.projectToken, withStatusCode: 200)
                waitUntil { done in
                    flushingManager.flushData(completion: { _ in done() })
                }
                expect { try database.fetchTrackEvent().count }.to(equal(0))
            }

            it("should retry flushing event `configuration.flushEventMaxRetries` times on weird errors") {
                try! database.trackEvent(with: eventData, into: configuration.mainProject)
                NetworkStubbing.stubNetwork(forProjectToken: configuration.projectToken, withStatusCode: 418)
                for attempt in 1...4 {
                    waitUntil { done in
                        flushingManager.flushData(completion: { _ in done() })
                    }
                    expect { try database.fetchTrackEvent().count }.to(equal(1))
                    expect { try database.fetchTrackEvent().first?.databaseObjectProxy.retries }.to(equal(attempt))
                }
                waitUntil { done in
                    flushingManager.flushData(completion: { _ in done() })
                }
                expect { try database.fetchTrackEvent().count }.to(equal(0))
            }

            it("should retry flushing event forever on 500 errors") {
                try! database.trackEvent(with: eventData, into: configuration.mainProject)
                NetworkStubbing.stubNetwork(forProjectToken: configuration.projectToken, withStatusCode: 500)
                for _ in 1...10 {
                    waitUntil { done in
                        flushingManager.flushData(completion: { _ in done() })
                    }
                    expect { try database.fetchTrackEvent().count }.to(equal(1))
                }
            }
            context("flushing order") {
                func checkFlushOrder() {
                    waitUntil { done in
                        var id = 1
                        NetworkStubbing.stubNetwork(
                            forProjectToken: configuration.projectToken,
                            withStatusCode: 200,
                            withDelay: 0,
                            withResponseData: nil,
                            withRequestHook: { request in
                                let payload = try! JSONSerialization.jsonObject(
                                    with: request.httpBodyStream!.readFully(),
                                    options: []
                                ) as? NSDictionary ?? NSDictionary()
                                let properties = payload["properties"] as? NSDictionary
                                expect(properties?["id"] as? Int).to(equal(id))
                                id += 1
                                if id == 6 {
                                    done()
                                }
                            }
                        )
                        flushingManager.flushData()
                    }
                }

                it("should flush customer updates in correct order") {
                    for id in 1...5 {
                        try! database.identifyCustomer(
                            with: [.properties(["id": .int(id)])],
                            into: configuration.mainProject
                        )
                    }
                    checkFlushOrder()
                }

                it("should flush events in correct order") {
                    for id in 1...5 {
                        try! database.trackEvent(
                            with: [.properties(["id": .int(id)])],
                            into: configuration.mainProject
                        )
                    }
                    checkFlushOrder()
                }
            }

            it("should track age for events") {
                let eventData: [DataType] = [
                    .timestamp(Date().timeIntervalSince1970 - 1),
                    .properties(["customprop": .string("customval")]),
                    .eventType(Constants.EventTypes.sessionStart),
                    .pushNotificationToken(token: "tokenthatisgoingtobeignored", authorized: true)
                ]
                try! database.trackEvent(
                    with: eventData,
                    into: configuration.mainProject
                )
                waitUntil { done in
                    NetworkStubbing.stubNetwork(
                        forProjectToken: configuration.projectToken,
                        withStatusCode: 200,
                        withDelay: 0,
                        withResponseData: nil,
                        withRequestHook: { request in
                            let payload = try! JSONSerialization.jsonObject(
                                with: request.httpBodyStream!.readFully(),
                                options: []
                            ) as? NSDictionary ?? NSDictionary()
                            expect(payload["age"] as? Double).notTo(beNil())
                            expect(payload["timestamp"] as? Double).to(beNil())
                            expect(payload["age"] as? Double).to(beGreaterThan(0))
                            done()
                        }
                    )
                    flushingManager.flushData()
                }
            }

            it("should track timestamp for push events") {
                let timestamp = Date().timeIntervalSince1970
                let eventData: [DataType] = [
                    .timestamp(timestamp),
                    .properties(["customprop": .string("customval")]),
                    .eventType(Constants.EventTypes.pushOpen),
                    .pushNotificationToken(token: "tokenthatisgoingtobeignored", authorized: true)
                ]
                try! database.trackEvent(
                    with: eventData,
                    into: configuration.mainProject
                )
                waitUntil { done in
                    NetworkStubbing.stubNetwork(
                        forProjectToken: configuration.projectToken,
                        withStatusCode: 200,
                        withDelay: 0,
                        withResponseData: nil,
                        withRequestHook: { request in
                            let payload = try! JSONSerialization.jsonObject(
                                with: request.httpBodyStream!.readFully(),
                                options: []
                            ) as? NSDictionary ?? NSDictionary()
                            expect(payload["age"] as? Double).to(beNil())
                            expect(payload["timestamp"] as? Double).notTo(beNil())
                            expect(payload["timestamp"] as? Double).to(equal(timestamp))
                            done()
                        }
                    )
                    flushingManager.flushData()
                }
            }
        }
    }
}
