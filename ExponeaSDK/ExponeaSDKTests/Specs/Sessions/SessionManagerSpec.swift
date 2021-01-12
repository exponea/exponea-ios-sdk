//
//  SessionManagerSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 23/03/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Nimble
import Quick

@testable import ExponeaSDK
@testable import ExponeaSDKShared

class SessionManagerSpec: QuickSpec {
    class MockSessionTrackingDelegate: SessionTrackingDelegate {
        var sessionStarts: [TimeInterval] = []
        var sessionEnds: [(TimeInterval, TimeInterval)] = []

        func trackSessionStart(at timestamp: TimeInterval) {
            sessionStarts.append(timestamp)
        }

        func trackSessionEnd(at timestamp: TimeInterval, withDuration duration: TimeInterval) {
            sessionEnds.append((timestamp, duration))
        }
    }

    override func spec() {
        var sessionManager: SessionManager!
        var trackingDelegate: MockSessionTrackingDelegate!
        func setup(automaticSessionTracking: Bool) {
            var configuration = try! Configuration(
                projectToken: "mock-project-token",
                authorization: .none,
                baseUrl: "mock-base-url",
                appGroup: "mock-app-group",
                defaultProperties: nil
            )
            configuration.sessionTimeout = 100
            configuration.automaticSessionTracking = automaticSessionTracking
            trackingDelegate = MockSessionTrackingDelegate()
            sessionManager = SessionManager(
                configuration: configuration,
                userDefaults: MockUserDefaults(),
                trackingDelegate: trackingDelegate
            )
        }

        describe("automatic session tracking") {
            beforeEach {
                setup(automaticSessionTracking: true)
            }

            it("should do nothing when manually tracking") {
                sessionManager.manualSessionStart()
                sessionManager.manualSessionEnd()

                expect(trackingDelegate.sessionStarts.count).to(equal(0))
                expect(trackingDelegate.sessionEnds.count).to(equal(0))
            }

            it("should start initial session start") {
                sessionManager.applicationDidBecomeActive(at: 10)
                expect(trackingDelegate.sessionStarts.count).to(equal(1))
                expect(trackingDelegate.sessionStarts[0]).to(equal(10))
            }

            it("should track session end when background work is run") {
                sessionManager.applicationDidBecomeActive(at: 10)
                sessionManager.applicationDidEnterBackground(at: 100)
                sessionManager.doSessionTimeoutBackgroundWork(at: 200)

                expect(trackingDelegate.sessionStarts.count).to(equal(1))
                expect(trackingDelegate.sessionStarts[0]).to(equal(10))
                expect(trackingDelegate.sessionEnds.count).to(equal(1))
                expect(trackingDelegate.sessionEnds[0].0).to(equal(100))
                expect(trackingDelegate.sessionEnds[0].1).to(equal(90))
            }

            it("should automatically end session on next start if background task is not run and session times out") {
                sessionManager.applicationDidBecomeActive(at: 10)
                sessionManager.applicationDidEnterBackground(at: 100)
                sessionManager.applicationDidBecomeActive(at: 400)

                expect(trackingDelegate.sessionStarts.count).to(equal(2))
                expect(trackingDelegate.sessionStarts[0]).to(equal(10))
                expect(trackingDelegate.sessionStarts[1]).to(equal(400))
                expect(trackingDelegate.sessionEnds.count).to(equal(1))
                expect(trackingDelegate.sessionEnds[0].0).to(equal(100))
                expect(trackingDelegate.sessionEnds[0].1).to(equal(90))
            }

            it("should resume session on next start if within session timeout") {
                sessionManager.applicationDidBecomeActive(at: 10)
                sessionManager.applicationDidEnterBackground(at: 100)
                sessionManager.applicationDidBecomeActive(at: 150)

                expect(trackingDelegate.sessionStarts.count).to(equal(1))
                expect(trackingDelegate.sessionStarts[0]).to(equal(10))
                expect(trackingDelegate.sessionEnds.count).to(equal(0))
            }

            it("should aumatically stop and start new session if app was terminated") {
                sessionManager.applicationDidBecomeActive(at: 10)
                // app was killed so there is no applicationDidEnterBackground
                sessionManager.applicationDidBecomeActive(at: 150)

                expect(trackingDelegate.sessionStarts.count).to(equal(2))
                expect(trackingDelegate.sessionStarts[0]).to(equal(10))
                expect(trackingDelegate.sessionStarts[1]).to(equal(150))
                expect(trackingDelegate.sessionEnds.count).to(equal(1))
                expect(trackingDelegate.sessionEnds[0].0).to(equal(150))
                expect(trackingDelegate.sessionEnds[0].1).to(equal(140))
            }
        }

        describe("manual session tracking") {
            beforeEach {
                setup(automaticSessionTracking: false)
            }

            it("should do nothing on lifecycle callbacks") {
                sessionManager.applicationDidBecomeActive()
                sessionManager.applicationDidEnterBackground()
                sessionManager.doSessionTimeoutBackgroundWork()

                expect(trackingDelegate.sessionStarts.count).to(equal(0))
                expect(trackingDelegate.sessionEnds.count).to(equal(0))
            }

            it("should manually track session start") {
                sessionManager.manualSessionStart(at: 10)

                expect(trackingDelegate.sessionStarts.count).to(equal(1))
                expect(trackingDelegate.sessionStarts[0]).to(equal(10))
            }

            it("should manually track session end") {
                sessionManager.manualSessionStart(at: 10)
                sessionManager.manualSessionEnd(at: 100)

                expect(trackingDelegate.sessionEnds.count).to(equal(1))
                expect(trackingDelegate.sessionEnds[0].0).to(equal(100))
                expect(trackingDelegate.sessionEnds[0].1).to(equal(90))
            }
        }
    }
}
