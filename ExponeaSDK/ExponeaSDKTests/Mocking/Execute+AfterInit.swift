//
//  Execute+AfterInit.swift
//  ExponeaSDKTests
//
//  Created by Ankmara on 07.02.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import XCTest
import Quick
import Nimble
import ExponeaSDKObjC

@testable import ExponeaSDK
@testable import ExponeaSDKShared

class ExponeaSpecInitSpec: QuickSpec {

    private var counter: Int = 0
    private let sdkInstance = MockExponeaImplementation()

    func failMethod() throws {
        throw NSError(domain: "error", code: 0)
    }

    func successMethod() {
        counter += 1
    }

    func successTryMethod() throws {
        let name = "test"
        if name != "test" {
            throw NSError(domain: "error", code: 99)
        } else {
            counter += 1
        }
    }

    override func spec() {
        context("executing after exponea init") {
            let manager = self.sdkInstance.afterInit
            it("After init manager") {
                /// Counter += 1
                manager.doActionAfterExponeaInit(self.increment)
                expect(manager.actionBlocks.count).to(equal(1))
                /// Counter += 1
                self.sdkInstance.executeSafely(self.increment)
                expect(manager.actionBlocks.count).to(equal(2))
                waitUntil(timeout: .seconds(10)) { done in
                    expect {
                        manager.doActionAfterExponeaInit {
                            expect {
                                try self.failMethod()
                            }.to(throwError())
                        }
                    }.toNot(throwError())
                    expect(manager.actionBlocks.count).to(equal(3))
                    DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                        /// Counter += 1
                        manager.doActionAfterExponeaInit(self.increment)
                        expect(manager.actionBlocks.count).to(equal(4))
                        done()
                    }
                }
                self.sdkInstance.executeSafely(self.increment)
                expect(manager.actionBlocks.count).to(equal(5))
                self.sdkInstance.configure(plistName: "ExponeaConfig") // TODO:  modify also for "ExponeaConfigStream"
                expect(manager.actionBlocks.isEmpty).to(beTruthy())
                expect(self.counter).to(equal(4))
                /// Counter += 1
                manager.doActionAfterExponeaInit(self.increment)
                expect(manager.actionBlocks.isEmpty).to(beTruthy())
                expect {
                    /// Counter += 1
                    try manager.doActionAfterExponeaInit(self.successTryMethod)
                    expect(manager.actionBlocks.isEmpty).to(beTruthy())
                }.toNot(throwError())
                expect(self.counter).to(equal(6))
                waitUntil(timeout: .seconds(10)) { done in
                    expect {
                        try manager.doActionAfterExponeaInit {
                            try self.failMethod()
                        }
                    }.to(throwError())
                    DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                        /// Counter += 1
                        manager.doActionAfterExponeaInit(self.increment)
                        expect(manager.actionBlocks.isEmpty).to(beTruthy())
                        done()
                    }
                }
                expect(self.counter).to(equal(7))
                /// Just clean
                self.clean()
                expect(self.counter).to(equal(0))
                waitUntil(timeout: .seconds(10)) { done in
                    self.sdkInstance.executeSafely {
                        try self.failMethod()
                    } errorHandler: { error in
                        expect((error as NSError).domain).to(equal("error"))
                        self.increment()
                        done()
                    }
                }
                expect(self.counter).to(equal(1))
            }
        }
    }

    @discardableResult
    func clean() -> Int {
        counter = 0
        let manager = self.sdkInstance.afterInit
        manager.clean()
        return manager.actionBlocks.count
    }

    func increment() {
        counter += 1
    }
}

class ExpoInitManagerSpec: QuickSpec {

    /// Thread-safe record of how many times each action ran.
    final class ExecutionRecorder {
        private let lock = NSLock()
        private var runs: [Int: Int] = [:]

        func record(_ id: Int) {
            lock.lock()
            defer { lock.unlock() }
            runs[id, default: 0] += 1
        }

        var runCounts: [Int: Int] {
            lock.lock()
            defer { lock.unlock() }
            return runs
        }
    }

    /// Thread-safe record of push delegate calls and whether each one came on main thread.
    final class ThreadRecordingPushDelegate: PushNotificationManagerDelegate {
        private let lock = NSLock()
        private var recorded: [(kind: String, onMainThread: Bool)] = []
        var onCall: (() -> Void)?

        func pushNotificationOpened(
            with action: ExponeaNotificationActionType,
            value: String?,
            extraData: [AnyHashable: Any]?
        ) {
            record("opened")
        }

        func silentPushNotificationReceived(extraData: [AnyHashable: Any]?) {
            record("silent")
        }

        var calls: [(kind: String, onMainThread: Bool)] {
            lock.lock()
            defer { lock.unlock() }
            return recorded
        }

        private func record(_ kind: String) {
            lock.lock()
            recorded.append((kind, Thread.isMainThread))
            lock.unlock()
            onCall?()
        }
    }

    static func makePushManager() -> PushNotificationManager {
        let trackingManager = MockTrackingManager(onEventCallback: { _, _ in })
        return PushNotificationManager(
            trackingConsentManager: TrackingConsentManager(trackingManager: trackingManager),
            trackingManager: trackingManager,
            swizzlingEnabled: false,
            requirePushAuthorization: true,
            appGroup: "mock-app-group",
            tokenTrackFrequency: .onTokenChange,
            currentPushToken: nil,
            lastTokenTrackDate: Date(),
            urlOpener: MockUrlOpener()
        )
    }

    // Consent is required and missing, so nothing is tracked and only the delegate is notified
    static func makePushOpenedData(silent: Bool) -> PushOpenedData {
        PushOpenedData(
            silent: silent,
            campaignData: CampaignData(),
            actionType: .openApp,
            actionValue: nil,
            eventType: .pushOpened,
            eventData: [],
            extraData: ["push": silent ? "silent" : "opened"],
            consentCategoryTracking: nil,
            hasTrackingConsent: false,
            considerConsent: true,
            origin: nil
        )
    }

    override func spec() {
        describe("ExpoInitManager") {
            beforeEach {
                IntegrationManager.shared.isStopped = false
            }

            it("replays queued actions exactly once and runs later actions directly") {
                let manager = ExpoInitManager(isConfigured: { true })
                let recorder = ExecutionRecorder()

                manager.doActionAfterExponeaInit { recorder.record(1) }
                manager.doActionAfterExponeaInit { recorder.record(2) }
                expect(manager.actionBlocks.count).to(equal(2))
                expect(recorder.runCounts).to(beEmpty())

                manager.setStatus(status: .configured)
                expect(recorder.runCounts).to(equal([1: 1, 2: 1]))
                expect(manager.actionBlocks).to(beEmpty())

                manager.doActionAfterExponeaInit { recorder.record(3) }
                expect(recorder.runCounts).to(equal([1: 1, 2: 1, 3: 1]))
                expect(manager.actionBlocks).to(beEmpty())

                // Repeated configuration must not replay anything again
                manager.setStatus(status: .configured)
                expect(recorder.runCounts).to(equal([1: 1, 2: 1, 3: 1]))
            }

            it("keeps queued actions while SDK dependencies are not ready yet") {
                var dependenciesReady = false
                let manager = ExpoInitManager(isConfigured: { dependenciesReady })
                let recorder = ExecutionRecorder()

                manager.doActionAfterExponeaInit { recorder.record(1) }
                manager.setStatus(status: .configured)
                expect(recorder.runCounts).to(beEmpty())
                expect(manager.actionBlocks.count).to(equal(1))

                dependenciesReady = true
                manager.setStatus(status: .configured)
                expect(recorder.runCounts).to(equal([1: 1]))
            }

            it("drops queued actions and queues again after reset to notInitialized") {
                let manager = ExpoInitManager(isConfigured: { true })
                let recorder = ExecutionRecorder()

                manager.setStatus(status: .configured)
                manager.setStatus(status: .notInitialized)
                manager.doActionAfterExponeaInit { recorder.record(1) }
                expect(manager.actionBlocks.count).to(equal(1))

                manager.setStatus(status: .notInitialized)
                expect(manager.actionBlocks).to(beEmpty())

                manager.setStatus(status: .configured)
                expect(recorder.runCounts).to(beEmpty())
            }

            it("does not deadlock when a log hook calls back into the manager while cleaning") {
                let manager = ExpoInitManager(isConfigured: { true })
                manager.doActionAfterExponeaInit {}
                let previousLogLevel = Exponea.logger.logLevel
                Exponea.logger.logLevel = .verbose
                var hookCalledBack = false
                // A host app's log hook that calls back into the SDK
                let hookId = Exponea.logger.addLogHook { message in
                    guard message.contains("have been deleted") else { return }
                    manager.doActionAfterExponeaInit {}
                    hookCalledBack = true
                }
                var cleanFinished = false

                waitUntil(timeout: .seconds(3)) { done in
                    DispatchQueue.global(qos: .userInitiated).async {
                        manager.clean()
                        cleanFinished = true
                        done()
                    }
                }
                Exponea.logger.removeLogHook(with: hookId)
                Exponea.logger.logLevel = previousLogLevel

                expect(cleanFinished).to(beTrue())
                // Read the state only when clean() returned, a deadlocked manager would block this thread too
                if cleanFinished {
                    expect(hookCalledBack).to(beTrue())
                    expect(manager.actionBlocks.count).to(equal(1))
                }
            }

            it("does not lose actions appended from background threads during replay") {
                let manager = ExpoInitManager(isConfigured: { true })
                let recorder = ExecutionRecorder()
                let queuedCount = 50
                let concurrentCount = 200
                let replayStarted = DispatchSemaphore(value: 0)

                // The first queued action holds the replay open while other threads keep appending
                manager.doActionAfterExponeaInit {
                    replayStarted.signal()
                    Thread.sleep(forTimeInterval: 0.2)
                    recorder.record(0)
                }
                for id in 1..<queuedCount {
                    manager.doActionAfterExponeaInit { recorder.record(id) }
                }

                waitUntil(timeout: .seconds(10)) { done in
                    let group = DispatchGroup()
                    DispatchQueue.global(qos: .userInitiated).async(group: group) {
                        manager.setStatus(status: .configured)
                    }
                    DispatchQueue.global(qos: .userInitiated).async(group: group) {
                        replayStarted.wait()
                        DispatchQueue.concurrentPerform(iterations: concurrentCount) { index in
                            let id = queuedCount + index
                            manager.doActionAfterExponeaInit { recorder.record(id) }
                        }
                    }
                    group.notify(queue: .main, execute: done)
                }

                let counts = recorder.runCounts
                expect(counts.count).to(equal(queuedCount + concurrentCount))
                expect(counts.values.allSatisfy { $0 == 1 }).to(beTrue())
                expect(manager.actionBlocks).to(beEmpty())
            }

            it("does not lose actions appended concurrently with switching to configured") {
                for _ in 0..<20 {
                    let manager = ExpoInitManager(isConfigured: { true })
                    let recorder = ExecutionRecorder()
                    let concurrentCount = 100

                    waitUntil(timeout: .seconds(10)) { done in
                        let group = DispatchGroup()
                        DispatchQueue.global(qos: .userInitiated).async(group: group) {
                            DispatchQueue.concurrentPerform(iterations: concurrentCount) { id in
                                manager.doActionAfterExponeaInit { recorder.record(id) }
                            }
                        }
                        DispatchQueue.global(qos: .userInitiated).async(group: group) {
                            manager.setStatus(status: .configured)
                        }
                        group.notify(queue: .main, execute: done)
                    }

                    let counts = recorder.runCounts
                    expect(counts.count).to(equal(concurrentCount))
                    expect(counts.values.allSatisfy { $0 == 1 }).to(beTrue())
                    expect(manager.actionBlocks).to(beEmpty())
                }
            }

            it("opens a deferred deeplink on main thread when init finishes on a background thread") {
                let manager = ExpoInitManager(isConfigured: { true })
                var openedURL: URL?
                var openedOnMainThread: Bool?

                waitUntil(timeout: .seconds(5)) { done in
                    let urlOpener = UrlOpener(
                        connectedWindowScenesProvider: { [] },
                        openURLHandler: { url, _ in
                            openedURL = url
                            openedOnMainThread = Thread.isMainThread
                            done()
                        }
                    )
                    // Same shape as a cold-start push tap: the push-open action is queued before
                    // init and replayed by whichever (background) thread finishes the configuration
                    manager.doActionAfterExponeaInit { urlOpener.openDeeplink("exponea://deeplink") }
                    DispatchQueue.global(qos: .userInitiated).async {
                        manager.setStatus(status: .configured)
                    }
                }

                expect(openedURL?.absoluteString).to(equal("exponea://deeplink"))
                expect(openedOnMainThread).to(beTrue())
            }

            it("calls the push delegate on main thread when a deferred push open is replayed on a background thread") {
                let manager = ExpoInitManager(isConfigured: { true })
                let pushManager = ExpoInitManagerSpec.makePushManager()
                let delegate = ThreadRecordingPushDelegate()
                pushManager.delegate = delegate

                waitUntil(timeout: .seconds(5)) { done in
                    delegate.onCall = {
                        if delegate.calls.count == 2 { done() }
                    }
                    // Same shape as a cold-start push tap: queued before init, replayed by a background thread
                    manager.doActionAfterExponeaInit {
                        pushManager.handlePushOpenedUnsafe(pushOpenedData: ExpoInitManagerSpec.makePushOpenedData(silent: false))
                    }
                    manager.doActionAfterExponeaInit {
                        pushManager.handlePushOpenedUnsafe(pushOpenedData: ExpoInitManagerSpec.makePushOpenedData(silent: true))
                    }
                    DispatchQueue.global(qos: .userInitiated).async {
                        manager.setStatus(status: .configured)
                    }
                }

                expect(delegate.calls.map { $0.kind }).to(equal(["opened", "silent"]))
                expect(delegate.calls.map { $0.onMainThread }).to(equal([true, true]))
            }

            it("delivers push opens received before the delegate was set on main thread") {
                let pushManager = ExpoInitManagerSpec.makePushManager()
                let delegate = ThreadRecordingPushDelegate()

                // No delegate yet, so both pushes are stored until one is set
                waitUntil(timeout: .seconds(5)) { done in
                    DispatchQueue.global(qos: .userInitiated).async {
                        pushManager.handlePushOpenedUnsafe(pushOpenedData: ExpoInitManagerSpec.makePushOpenedData(silent: false))
                        pushManager.handlePushOpenedUnsafe(pushOpenedData: ExpoInitManagerSpec.makePushOpenedData(silent: true))
                        done()
                    }
                }
                expect(pushManager.pendingOpenedPushes.count).toEventually(equal(2))

                waitUntil(timeout: .seconds(5)) { done in
                    delegate.onCall = {
                        if delegate.calls.count == 2 { done() }
                    }
                    // The delegate can be set from a background thread, e.g. by configure() on the init queue
                    DispatchQueue.global(qos: .userInitiated).async {
                        pushManager.delegate = delegate
                    }
                }

                expect(delegate.calls.map { $0.kind }).to(equal(["opened", "silent"]))
                expect(delegate.calls.map { $0.onMainThread }).to(equal([true, true]))
                expect(pushManager.pendingOpenedPushes).to(beEmpty())
            }
        }
    }
}
