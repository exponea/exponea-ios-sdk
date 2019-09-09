//
//  TrackEventSpec.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 13/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Mockingjay

@testable import ExponeaSDK

class TrackEventSpec: QuickSpec {

    override func spec() {
        _ = MockUserNotificationCenter.shared
        describe("Tracking events") {
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
                database = try! MockDatabase()
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
                    expect { try database.fetchTrackEvent().first?.retries.intValue }.to(equal(i))
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
        }
    }

    func stubNetwork(withStatusCode statusCode: Int) {
        let stubResponse = HTTPURLResponse(url: URL(string: "mock-url")!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        let stubData = "mock-response".data(using: String.Encoding.utf8, allowLossyConversion: true)!
        MockingjayProtocol.addStub(matcher: { request in return true }) { (request) -> (Response) in
            return Response.success(stubResponse, .content(stubData))
        }
    }

    func unstubNetwork() {
        MockingjayProtocol.removeAllStubs()
    }
}
