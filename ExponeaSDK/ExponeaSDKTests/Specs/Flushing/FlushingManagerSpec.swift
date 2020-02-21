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

                flushingManager = try! FlushingManager(database: database, repository: repository)

                eventData = [
                    .projectToken(configuration.projectToken!),
                    .properties(MockData().properties)
                ]
            }

            afterEach {
                NetworkStubbing.unstubNetwork()
            }

            it("should only allow one thread to flush") {
                try! database.trackEvent(with: eventData)

                var networkRequests: Int = 0
                NetworkStubbing.stubNetwork(
                    forProjectToken: configuration.projectToken!,
                    withStatusCode: 200,
                    withRequestHook: { _ in networkRequests += 1 }
                )

                waitUntil { done in
                    let group = DispatchGroup()
                    for _ in 0..<10 {
                        group.enter()
                        DispatchQueue.global(qos: .background).async {
                            flushingManager.flushData(completion: {group.leave()})
                        }
                    }
                    group.notify(queue: .main, execute: done)
                }

                expect(networkRequests).to(equal(1))
            }

            it("should flush event") {
                try! database.trackEvent(with: eventData)
                NetworkStubbing.stubNetwork(forProjectToken: configuration.projectToken!, withStatusCode: 200)
                waitUntil { done in
                    flushingManager.flushData(completion: {done()})
                }
                expect { try database.fetchTrackEvent().count }.to(equal(0))
            }

            it("should retry flushing event `configuration.flushEventMaxRetries` times on weird errors") {
                try! database.trackEvent(with: eventData)
                NetworkStubbing.stubNetwork(forProjectToken: configuration.projectToken!, withStatusCode: 418)
                for attempt in 1...4 {
                    waitUntil { done in
                        flushingManager.flushData(completion: {done()})
                    }
                    expect { try database.fetchTrackEvent().count }.to(equal(1))
                    expect { try database.fetchTrackEvent().first?.retries }.to(equal(attempt))
                }
                waitUntil { done in
                    flushingManager.flushData(completion: {done()})
                }
                expect { try database.fetchTrackEvent().count }.to(equal(0))
            }

            it("should retry flushing event forever on 500 errors") {
                try! database.trackEvent(with: eventData)
                NetworkStubbing.stubNetwork(forProjectToken: configuration.projectToken!, withStatusCode: 500)
                for _ in 1...10 {
                    waitUntil { done in
                        flushingManager.flushData(completion: {done()})
                    }
                    expect { try database.fetchTrackEvent().count }.to(equal(1))
                }
            }
        }
    }
}
