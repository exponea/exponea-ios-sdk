//
//  CompletionGuaranteesSpec.swift
//  ExponeaSDKTests
//
//  Created by Bloomreach on 03/06/2026.
//  Copyright © 2026 Exponea. All rights reserved.
//

import Foundation
import Nimble
import Quick
import XCTest

@testable import ExponeaSDK
@testable import ExponeaSDKShared

/// Verifies the "completion fires exactly once on the main thread" contract for the
/// completion-bearing public APIs of `ExponeaType` -- `flushData(completion:)`,
/// `anonymize(completion:)`, and
/// `anonymize(exponeaIntegrationType:exponeaProjectMapping:completion:)` -- on the
/// SDK-stopped and prior-internal-exception short-circuit paths. For `flushData(completion:)`,
/// the completion delivers `FlushResult.error(_:)` carrying the corresponding `ExponeaError`
/// (`.isStopped` or `.nsExceptionInconsistency`). The spec also covers the empty-queue happy
/// path on the main thread and the normalization of the inner `.stoppedProcess` error to the
/// public `.isStopped` case at the trampoline boundary.
final class CompletionGuaranteesSpec: QuickSpec {

    override func spec() {

        describe("completion guarantees") {

            beforeEach {
                IntegrationManager.shared.isStopped = false
                // Match the sibling AnonymizeWithIntegrationAndCompletionSpec pattern: clear the
                // shared Core Data store so events tracked by `configure(...)` in previous specs
                // do not pollute the flushing pipeline of tests that rely on a clean queue.
                let database = try! DatabaseManager()
                try! database.clear()
            }

            afterEach {
                NetworkStubbing.unstubNetwork()
                IntegrationManager.shared.isStopped = false
                // Remove the persisted `isStopped` key written by IntegrationManager.willSet so
                // a later spec does not observe stale state from this one.
                UserDefaults(suiteName: Constants.General.userDefaultsSuite)?
                    .removeObject(forKey: "isStopped")
            }

            // MARK: - anonymize(exponeaIntegrationType:exponeaProjectMapping:completion:)

            context("anonymize(exponeaIntegrationType:exponeaProjectMapping:completion:)") {

                it("fires completion on the main thread when SDK is stopped") {
                    let exponea = ExponeaInternal()
                    Exponea.shared = exponea
                    IntegrationManager.shared.isStopped = true

                    waitUntil(timeout: .seconds(2)) { done in
                        Exponea.shared.anonymize(
                            exponeaIntegrationType: ExponeaProject(
                                projectToken: "mock-token",
                                authorization: .token("mock-token")
                            ),
                            exponeaProjectMapping: nil,
                            completion: {
                                expect(Thread.isMainThread).to(beTrue())
                                done()
                            }
                        )
                    }
                }

                it("fires completion on the main thread after a prior internal exception") {
                    let exponea = ExponeaInternal()
                    Exponea.shared = exponea
                    exponea.nsExceptionRaised = true

                    waitUntil(timeout: .seconds(2)) { done in
                        Exponea.shared.anonymize(
                            exponeaIntegrationType: ExponeaProject(
                                projectToken: "mock-token",
                                authorization: .token("mock-token")
                            ),
                            exponeaProjectMapping: nil,
                            completion: {
                                expect(Thread.isMainThread).to(beTrue())
                                done()
                            }
                        )
                    }
                }

                it("fires completion exactly once when SDK is stopped") {
                    let exponea = ExponeaInternal()
                    Exponea.shared = exponea
                    IntegrationManager.shared.isStopped = true

                    var callCount = 0
                    Exponea.shared.anonymize(
                        exponeaIntegrationType: ExponeaProject(
                            projectToken: "mock-token",
                            authorization: .token("mock-token")
                        ),
                        exponeaProjectMapping: nil,
                        completion: {
                            expect(Thread.isMainThread).to(beTrue())
                            callCount += 1
                        }
                    )

                    expect(callCount).toEventually(equal(1), timeout: .seconds(2))
                    // Drain the main runloop to surface any erroneously-queued additional
                    // DispatchQueue.main.async invocations.
                    RunLoop.current.run(until: Date().addingTimeInterval(0.5))
                    expect(callCount).to(equal(1))
                }
            }

            // MARK: - anonymize(completion:)

            context("anonymize(completion:)") {

                it("fires completion on the main thread when SDK is stopped") {
                    let exponea = ExponeaInternal()
                    Exponea.shared = exponea
                    IntegrationManager.shared.isStopped = true

                    waitUntil(timeout: .seconds(2)) { done in
                        Exponea.shared.anonymize {
                            expect(Thread.isMainThread).to(beTrue())
                            done()
                        }
                    }
                }

                it("fires completion on the main thread after a prior internal exception") {
                    let exponea = ExponeaInternal()
                    Exponea.shared = exponea
                    exponea.nsExceptionRaised = true

                    waitUntil(timeout: .seconds(2)) { done in
                        Exponea.shared.anonymize {
                            expect(Thread.isMainThread).to(beTrue())
                            done()
                        }
                    }
                }

                it("fires completion exactly once when SDK is stopped") {
                    let exponea = ExponeaInternal()
                    Exponea.shared = exponea
                    IntegrationManager.shared.isStopped = true

                    var callCount = 0
                    Exponea.shared.anonymize {
                        expect(Thread.isMainThread).to(beTrue())
                        callCount += 1
                    }

                    expect(callCount).toEventually(equal(1), timeout: .seconds(2))
                    RunLoop.current.run(until: Date().addingTimeInterval(0.5))
                    expect(callCount).to(equal(1))
                }
            }

            // MARK: - flushData(completion:)

            context("flushData(completion:)") {

                it("fires completion on the main thread when SDK is stopped, FlushResult.error wraps isStopped") {
                    let exponea = ExponeaInternal()
                    Exponea.shared = exponea
                    IntegrationManager.shared.isStopped = true

                    waitUntil(timeout: .seconds(2)) { done in
                        Exponea.shared.flushData { result in
                            expect(Thread.isMainThread).to(beTrue())
                            guard case .error(let error) = result else {
                                XCTFail("Expected FlushResult.error, got \(result)")
                                done()
                                return
                            }
                            guard let exponeaError = error as? ExponeaError,
                                  case .isStopped = exponeaError else {
                                XCTFail("Expected ExponeaError.isStopped, got \(error)")
                                done()
                                return
                            }
                            done()
                        }
                    }
                }

                it("fires completion on the main thread after a prior internal exception, FlushResult.error wraps nsExceptionInconsistency") {
                    let exponea = ExponeaInternal()
                    Exponea.shared = exponea
                    exponea.nsExceptionRaised = true

                    waitUntil(timeout: .seconds(2)) { done in
                        Exponea.shared.flushData { result in
                            expect(Thread.isMainThread).to(beTrue())
                            guard case .error(let error) = result else {
                                XCTFail("Expected FlushResult.error, got \(result)")
                                done()
                                return
                            }
                            guard let exponeaError = error as? ExponeaError,
                                  case .nsExceptionInconsistency = exponeaError else {
                                XCTFail("Expected ExponeaError.nsExceptionInconsistency, got \(error)")
                                done()
                                return
                            }
                            done()
                        }
                    }
                }

                it("fires completion exactly once when SDK is stopped") {
                    let exponea = ExponeaInternal()
                    Exponea.shared = exponea
                    IntegrationManager.shared.isStopped = true

                    var callCount = 0
                    Exponea.shared.flushData { _ in
                        expect(Thread.isMainThread).to(beTrue())
                        callCount += 1
                    }

                    expect(callCount).toEventually(equal(1), timeout: .seconds(2))
                    RunLoop.current.run(until: Date().addingTimeInterval(0.5))
                    expect(callCount).to(equal(1))
                }

                it("fires completion on the main thread with FlushResult.error wrapping authorizationInsufficient when configured with Authorization.none") {
                    let exponea = ExponeaInternal()
                    Exponea.shared = exponea
                    Exponea.shared.configure(
                        Exponea.ProjectSettings(
                            projectToken: "mock-token",
                            authorization: .none
                        ),
                        pushNotificationTracking: .disabled,
                        flushingSetup: Exponea.FlushingSetup(mode: .manual)
                    )

                    waitUntil(timeout: .seconds(2)) { done in
                        Exponea.shared.flushData { result in
                            expect(Thread.isMainThread).to(beTrue())
                            guard case .error(let error) = result else {
                                XCTFail("Expected FlushResult.error, got \(result)")
                                done()
                                return
                            }
                            guard let exponeaError = error as? ExponeaError,
                                  case .authorizationInsufficient = exponeaError else {
                                XCTFail("Expected ExponeaError.authorizationInsufficient, got \(error)")
                                done()
                                return
                            }
                            done()
                        }
                    }
                }

                it("fires completion exactly once when configured with Authorization.none") {
                    let exponea = ExponeaInternal()
                    Exponea.shared = exponea
                    Exponea.shared.configure(
                        Exponea.ProjectSettings(
                            projectToken: "mock-token",
                            authorization: .none
                        ),
                        pushNotificationTracking: .disabled,
                        flushingSetup: Exponea.FlushingSetup(mode: .manual)
                    )

                    var callCount = 0
                    Exponea.shared.flushData { _ in
                        expect(Thread.isMainThread).to(beTrue())
                        callCount += 1
                    }

                    expect(callCount).toEventually(equal(1), timeout: .seconds(2))
                    RunLoop.current.run(until: Date().addingTimeInterval(0.5))
                    expect(callCount).to(equal(1))
                }

                it("fires completion on the main thread with FlushResult.success(0) when the flushing pipeline reports an empty queue") {
                    let exponea = ExponeaInternal()
                    Exponea.shared = exponea
                    Exponea.shared.configure(
                        Exponea.ProjectSettings(
                            projectToken: "mock-token",
                            authorization: .token("mock-token")
                        ),
                        pushNotificationTracking: .disabled,
                        flushingSetup: Exponea.FlushingSetup(mode: .manual)
                    )
                    // Replace the real flushing manager with a mock that synthesizes the empty-queue
                    // success path so the test does not depend on database state or network reachability.
                    let mockFlushingManager = MockFlushingManager()
                    mockFlushingManager.stubbedResult = .success(0)
                    exponea.flushingManager = mockFlushingManager

                    waitUntil(timeout: .seconds(2)) { done in
                        Exponea.shared.flushData { result in
                            expect(Thread.isMainThread).to(beTrue())
                            guard case .success(let count) = result else {
                                XCTFail("Expected FlushResult.success(0), got \(result)")
                                done()
                                return
                            }
                            expect(count).to(equal(0))
                            done()
                        }
                    }
                }

                it("remaps inner FlushResult.error(.stoppedProcess) to .error(.isStopped) at the trampoline") {
                    let exponea = ExponeaInternal()
                    Exponea.shared = exponea
                    Exponea.shared.configure(
                        Exponea.ProjectSettings(
                            projectToken: "mock-token",
                            authorization: .token("mock-token")
                        ),
                        pushNotificationTracking: .disabled,
                        flushingSetup: Exponea.FlushingSetup(mode: .manual)
                    )
                    // Stub the flushing manager to return the stopped-process error directly so the
                    // public API error mapping can be tested without triggering a real race condition.
                    let mockFlushingManager = MockFlushingManager()
                    mockFlushingManager.stubbedResult = .error(ExponeaError.stoppedProcess)
                    exponea.flushingManager = mockFlushingManager

                    waitUntil(timeout: .seconds(2)) { done in
                        Exponea.shared.flushData { result in
                            expect(Thread.isMainThread).to(beTrue())
                            guard case .error(let error) = result else {
                                XCTFail("Expected FlushResult.error, got \(result)")
                                done()
                                return
                            }
                            guard let exponeaError = error as? ExponeaError,
                                  case .isStopped = exponeaError else {
                                XCTFail("Expected ExponeaError.isStopped (remapped from .stoppedProcess), got \(error)")
                                done()
                                return
                            }
                            done()
                        }
                    }
                }

                it("fires completion on the main thread after the call was queued before configure(...) finished") {
                    // Stub the project endpoint so the deferred flush, drained synchronously
                    // inside configure(...), does not hit a real network. The status code is
                    // irrelevant for this test - we assert on the threading contract, not
                    // on the per-object upload outcome.
                    NetworkStubbing.stubNetwork(
                        forIntegrationType: .project(projectToken: "mock-token"),
                        withStatusCode: 200
                    )

                    let exponea = ExponeaInternal()
                    Exponea.shared = exponea
                    expect(exponea.afterInit.actionBlocks.isEmpty).to(beTrue())

                    waitUntil(timeout: .seconds(5)) { done in
                        Exponea.shared.flushData { _ in
                            expect(Thread.isMainThread).to(beTrue())
                            done()
                        }

                        // The call was placed before configure(...); the action must be queued,
                        // not invoked. The action is held in the pending state until
                        // configuration completes.
                        expect(exponea.afterInit.actionBlocks.count).to(equal(1))

                        // configure(...) switches the state to configured and replays the
                        // pending actions, which fires the deferred flushData against the
                        // now-configured pipeline. The trampoline then delivers the user
                        // callback on the main thread.
                        Exponea.shared.configure(
                            Exponea.ProjectSettings(
                                projectToken: "mock-token",
                                authorization: .token("mock-token")
                            ),
                            pushNotificationTracking: .disabled,
                            flushingSetup: Exponea.FlushingSetup(mode: .manual)
                        )
                    }
                }
            }
        }
    }
}

