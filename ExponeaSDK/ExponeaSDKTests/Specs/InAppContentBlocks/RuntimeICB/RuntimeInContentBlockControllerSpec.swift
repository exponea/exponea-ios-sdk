//
//  RuntimeInContentBlockControllerSpec.swift
//  ExponeaSDKTests
//
//  Copyright © 2026 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import ExponeaSDK

class RuntimeInContentBlockControllerSpec: QuickSpec {
    override func spec() {
        var manager: MockInAppContentBlocksManager!
        var controller: RuntimeInContentBlockController!

        beforeEach {
            manager = MockInAppContentBlocksManager()
            controller = RuntimeInContentBlockController(manager: manager)
        }

        describe("prefetch") {
            it("returns an empty map for empty ids") {
                waitUntil { done in
                    Task {
                        let result = await controller.prefetch(ids: [])
                        expect(result).to(beEmpty())
                        done()
                    }
                }
            }

            it("skips manager prefetch when placeholder is already cached as ready") {
                manager.availabilityByPlaceholder["ph1"] = .ready

                waitUntil { done in
                    Task {
                        let result = await controller.prefetch(ids: ["ph1"])
                        expect(result).to(equal(["ph1": .ready]))
                        expect(manager.prefetchCallCount).to(equal(0))
                        done()
                    }
                }
            }

            it("returns a per-id map after a cold prefetch completes") {
                manager.prefetchAvailabilityAfterFetch = .ready

                waitUntil { done in
                    Task {
                        let result = await controller.prefetch(ids: ["ph1", "ph2"])
                        expect(result).to(equal([
                            "ph1": .ready,
                            "ph2": .ready
                        ]))
                        expect(manager.prefetchCallCount).to(equal(1))
                        expect(manager.prefetchedIds).to(equal(["ph1", "ph2"]))
                        done()
                    }
                }
            }

            it("returns empty for placeholders with no eligible content after fetch") {
                manager.prefetchAvailabilityAfterFetch = .empty

                waitUntil { done in
                    Task {
                        let result = await controller.prefetch(ids: ["ph_empty"])
                        expect(result).to(equal(["ph_empty": .empty]))
                        expect(manager.prefetchCallCount).to(equal(1))
                        done()
                    }
                }
            }

            it("resolves concurrent prefetch calls for the same in-flight id to the real outcome") {
                manager.prefetchAvailabilityAfterFetch = .ready
                manager.prefetchDelay = 0.3

                waitUntil(timeout: .seconds(5)) { done in
                    var firstResult: [String: InAppContentBlockAvailability]?
                    var secondResult: [String: InAppContentBlockAvailability]?

                    controller.prefetch(ids: ["ph1"]) { result in
                        firstResult = result
                    }
                    controller.prefetch(ids: ["ph1"]) { result in
                        secondResult = result
                        expect(firstResult).to(equal(["ph1": .ready]))
                        expect(secondResult).to(equal(["ph1": .ready]))
                        expect(manager.prefetchCallCount).to(equal(1))
                        done()
                    }
                }
            }

            it("returns a complete result map when a batch mixes an in-flight id with a new cold id") {
                manager.prefetchAvailabilityAfterFetch = .ready
                manager.prefetchDelay = 0.3

                waitUntil(timeout: .seconds(5)) { done in
                    controller.prefetch(ids: ["ph_inflight"]) { _ in }

                    controller.prefetch(ids: ["ph_inflight", "ph_cold"]) { result in
                        expect(result["ph_inflight"]).to(equal(.ready))
                        expect(result["ph_cold"]).to(equal(.ready))
                        expect(result.count).to(equal(2))
                        expect(manager.prefetchCallCount).to(equal(2))
                        done()
                    }
                }
            }

            it("reuses controller state on a second prefetch without calling manager again") {
                manager.prefetchAvailabilityAfterFetch = .ready

                waitUntil { done in
                    Task {
                        _ = await controller.prefetch(ids: ["ph1"])
                        manager.resetPrefetchCalls()

                        let secondResult = await controller.prefetch(ids: ["ph1"])
                        expect(secondResult).to(equal(["ph1": .ready]))
                        expect(manager.prefetchCallCount).to(equal(0))
                        done()
                    }
                }
            }

            it("delivers the same result through the callback overload") {
                manager.prefetchAvailabilityAfterFetch = .ready

                waitUntil { done in
                    controller.prefetch(ids: ["ph1"]) { result in
                        expect(result).to(equal(["ph1": .ready]))
                        expect(manager.prefetchCallCount).to(equal(1))
                        done()
                    }
                }
            }

            it("mixes cached and cold ids in a single prefetch batch") {
                manager.availabilityByPlaceholder["ph_cached"] = .ready
                manager.prefetchAvailabilityAfterFetch = .ready

                waitUntil { done in
                    Task {
                        let result = await controller.prefetch(ids: ["ph_cached", "ph_cold"])
                        expect(result).to(equal([
                            "ph_cached": .ready,
                            "ph_cold": .ready
                        ]))
                        expect(manager.prefetchCallCount).to(equal(1))
                        expect(manager.prefetchedIds).to(equal(["ph_cold"]))
                        done()
                    }
                }
            }
        }

        describe("invalidate") {
            it("is a no-op for empty ids") {
                controller.invalidate(ids: [], reason: "noop")
                expect(manager.invalidatedPlaceholderIds).to(beEmpty())
                expect(manager.prefetchCallCount).to(equal(0))
            }

            it("eager invalidate clears manager cache and triggers background refetch") {
                manager.prefetchAvailabilityAfterFetch = .ready

                waitUntil(timeout: .seconds(3)) { done in
                    Task {
                        _ = await controller.prefetch(ids: ["ph1"])
                        manager.resetPrefetchCalls()

                        controller.invalidate(ids: ["ph1"], reason: "promo_changed", mode: .eager)
                        try await Task.sleep(nanoseconds: 200_000_000)

                        expect(manager.invalidatedPlaceholderIds.last).to(equal(["ph1"]))
                        expect(manager.prefetchCallCount).to(equal(1))
                        expect(manager.prefetchedIds).to(equal(["ph1"]))

                        manager.resetPrefetchCalls()
                        let secondResult = await controller.prefetch(ids: ["ph1"])
                        expect(secondResult).to(equal(["ph1": .ready]))
                        expect(manager.prefetchCallCount).to(equal(0))
                        done()
                    }
                }
            }

            it("lazy invalidate clears cache without refetch for a known placeholder") {
                manager.prefetchAvailabilityAfterFetch = .ready

                waitUntil(timeout: .seconds(3)) { done in
                    Task {
                        _ = await controller.prefetch(ids: ["ph1"])
                        manager.resetPrefetchCalls()

                        controller.invalidate(ids: ["ph1"], reason: "lazy_drop", mode: .lazy)
                        try await Task.sleep(nanoseconds: 200_000_000)

                        expect(manager.invalidatedPlaceholderIds.last).to(equal(["ph1"]))
                        expect(manager.prefetchCallCount).to(equal(0))

                        _ = await controller.prefetch(ids: ["ph1"])
                        expect(manager.prefetchCallCount).to(equal(1))
                        done()
                    }
                }
            }

            it("uses eager-prefetch semantics for an unknown placeholder id even in lazy mode") {
                manager.prefetchAvailabilityAfterFetch = .ready

                waitUntil(timeout: .seconds(3)) { done in
                    Task {
                        controller.invalidate(ids: ["ph_new"], reason: "first_call", mode: .lazy)
                        try await Task.sleep(nanoseconds: 200_000_000)

                        expect(manager.invalidatedPlaceholderIds.last).to(equal(["ph_new"]))
                        expect(manager.prefetchedIds).to(equal(["ph_new"]))

                        manager.resetPrefetchCalls()
                        let result = await controller.prefetch(ids: ["ph_new"])
                        expect(result).to(equal(["ph_new": .ready]))
                        expect(manager.prefetchCallCount).to(equal(0))
                        done()
                    }
                }
            }

            it("only invalidates and refetches the requested placeholder ids") {
                manager.prefetchAvailabilityAfterFetch = .ready

                waitUntil(timeout: .seconds(3)) { done in
                    Task {
                        _ = await controller.prefetch(ids: ["ph_a", "ph_b"])
                        manager.resetPrefetchCalls()

                        controller.invalidate(ids: ["ph_a"], reason: "targeted", mode: .eager)
                        try await Task.sleep(nanoseconds: 200_000_000)

                        expect(manager.invalidatedPlaceholderIds.last).to(equal(["ph_a"]))
                        expect(manager.prefetchedIds).to(equal(["ph_a"]))
                        done()
                    }
                }
            }

            it("logs the invalidate reason at verbose level") {
                let logger = MockLogger()
                logger.logLevel = .verbose
                Exponea.logger = logger

                waitUntil(timeout: .seconds(3)) { done in
                    controller.invalidate(ids: ["ph1"], reason: "promo_test_reason")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        expect(logger.messages.contains(where: { $0.contains("promo_test_reason") })).to(beTrue())
                        expect(logger.messages.contains(where: { $0.contains("Runtime ICB invalidate") })).to(beTrue())
                        done()
                    }
                }
            }
        }

        describe("availability") {
            it("resolves ready from manager cache when controller state is unknown") {
                manager.availabilityByPlaceholder["ph1"] = .ready

                waitUntil(timeout: .seconds(3)) { done in
                    controller.availability(id: "ph1", deadline: 1.0) { decision in
                        expect(decision).to(equal(.resolved(.ready)))
                        expect(manager.prefetchCallCount).to(equal(0))
                        done()
                    }
                }
            }

            it("returns resolved ready immediately for an already-cached placeholder") {
                manager.prefetchAvailabilityAfterFetch = .ready

                waitUntil(timeout: .seconds(3)) { done in
                    Task {
                        _ = await controller.prefetch(ids: ["ph1"])

                        let result = await controller.availability(id: "ph1", deadline: 1.0)

                        expect(result).to(equal(.resolved(.ready)))
                        done()
                    }
                }
            }

            it("returns resolved ready when fetch completes before deadline") {
                manager.prefetchAvailabilityAfterFetch = .ready

                waitUntil(timeout: .seconds(5)) { done in
                    controller.availability(id: "cold_ph", deadline: 2.0) { decision in
                        expect(decision).to(equal(.resolved(.ready)))
                        done()
                    }
                }
            }

            it("returns resolved empty when manager reports no content before deadline") {
                manager.prefetchAvailabilityAfterFetch = .empty

                waitUntil(timeout: .seconds(5)) { done in
                    controller.availability(id: "cold_ph", deadline: 2.0) { decision in
                        expect(decision).to(equal(.resolved(.empty)))
                        done()
                    }
                }
            }

            it("returns timed out when deadline elapses before fetch completes") {
                manager.prefetchAvailabilityAfterFetch = .ready
                manager.prefetchDelay = 0.5

                waitUntil(timeout: .seconds(5)) { done in
                    controller.availability(id: "slow_ph", deadline: 0.1) { decision in
                        expect(decision).to(equal(.timedOut))
                        done()
                    }
                }
            }

            it("populates cache after timeout so a subsequent call resolves immediately") {
                manager.prefetchAvailabilityAfterFetch = .ready
                manager.prefetchDelay = 0.3

                waitUntil(timeout: .seconds(5)) { done in
                    Task {
                        let first = await controller.availability(id: "late_ph", deadline: 0.05)
                        expect(first).to(equal(.timedOut))

                        try await Task.sleep(nanoseconds: 400_000_000)

                        let second = await controller.availability(id: "late_ph", deadline: 1.0)
                        expect(second).to(equal(.resolved(.ready)))
                        done()
                    }
                }
            }

            it("resolves all concurrent waiters for the same id when content becomes available") {
                manager.prefetchAvailabilityAfterFetch = .ready
                manager.prefetchDelay = 0.5

                waitUntil(timeout: .seconds(5)) { done in
                    var firstDecision: InAppContentBlockAvailabilityDecision?
                    var secondDecision: InAppContentBlockAvailabilityDecision?

                    controller.availability(id: "shared_ph", deadline: 2.0) { decision in
                        firstDecision = decision
                    }

                    controller.availability(id: "shared_ph", deadline: 2.0) { decision in
                        secondDecision = decision
                        expect(firstDecision).to(equal(.resolved(.ready)))
                        expect(secondDecision).to(equal(.resolved(.ready)))
                        done()
                    }
                }
            }

            it("never resolves with loading — times out if manager still reports loading after fetch") {
                manager.prefetchAvailabilityAfterFetch = .loading

                waitUntil(timeout: .seconds(5)) { done in
                    controller.availability(id: "loading_ph", deadline: 0.1) { decision in
                        expect(decision).to(equal(.timedOut))
                        done()
                    }
                }
            }
        }

        describe("SC-009 rapid invalidate deduplication") {
            it("issues at most one network fetch when invalidate is called three times in rapid succession") {
                manager.prefetchAvailabilityAfterFetch = .ready
                manager.prefetchDelay = 0.5

                waitUntil(timeout: .seconds(5)) { done in
                    controller.prefetch(ids: ["ph1"]) { _ in
                        manager.resetPrefetchCalls()
                        manager.prefetchDelay = 0.5

                        controller.invalidate(ids: ["ph1"], reason: "rapid_1", mode: .eager)
                        controller.invalidate(ids: ["ph1"], reason: "rapid_2", mode: .eager)
                        controller.invalidate(ids: ["ph1"], reason: "rapid_3", mode: .eager)

                        controller.prefetch(ids: ["ph1"]) { _ in
                            expect(manager.prefetchCallCount).to(equal(1))
                            done()
                        }
                    }
                }
            }

            it("issues at most one fetch for a cold id invalidated multiple times before any fetch completes") {
                manager.prefetchAvailabilityAfterFetch = .ready
                manager.prefetchDelay = 0.5

                waitUntil(timeout: .seconds(5)) { done in
                    controller.invalidate(ids: ["cold_ph"], reason: "first", mode: .eager)
                    controller.invalidate(ids: ["cold_ph"], reason: "second", mode: .eager)
                    controller.invalidate(ids: ["cold_ph"], reason: "third", mode: .eager)

                    controller.prefetch(ids: ["cold_ph"]) { _ in
                        expect(manager.prefetchCallCount).to(equal(1))
                        done()
                    }
                }
            }
        }

        describe("stale in-flight load on invalidate") {
            it("discards pre-invalidation fetch result and issues a fresh fetch") {
                let localManager = MockInAppContentBlocksManager()
                let localController = RuntimeInContentBlockController(manager: localManager)
                localManager.prefetchAvailabilityAfterFetch = .ready
                localManager.prefetchDelay = 0.5

                waitUntil(timeout: .seconds(5)) { done in
                    var firstResult: [String: InAppContentBlockAvailability]?

                    localController.prefetch(ids: ["ph1"]) { result in
                        firstResult = result
                    }

                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                        localController.invalidate(ids: ["ph1"], reason: "mid-flight", mode: .eager)

                        localController.prefetch(ids: ["ph1"]) { secondResult in
                            expect(firstResult).toNot(beNil())
                            expect(firstResult?["ph1"]).to(equal(.loading))
                            expect(secondResult["ph1"]).to(equal(.ready))
                            expect(localManager.prefetchCallCount).to(equal(2))
                            done()
                        }
                    }
                }
            }

            it("does not issue a proactive refetch when a lazy invalidation races an in-flight fetch") {
                // Regression: a .lazy invalidation arriving while a non-invalidation fetch is
                // in-flight used to unconditionally trigger a re-fetch when the stale result was
                // detected, turning .lazy into .eager for that ID.
                let localManager = MockInAppContentBlocksManager()
                let localController = RuntimeInContentBlockController(manager: localManager)
                localManager.prefetchAvailabilityAfterFetch = .ready
                localManager.prefetchDelay = 0.4

                waitUntil(timeout: .seconds(5)) { done in
                    localController.prefetch(ids: ["ph1"]) { _ in }

                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                        // Lazy invalidation mid-flight: drops state but must not trigger a new fetch.
                        localController.invalidate(ids: ["ph1"], reason: "lazy-race", mode: .lazy)

                        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                            // Only the original fetch (call #1) should have occurred.
                            // No proactive re-fetch from the stale-detection path.
                            expect(localManager.prefetchCallCount).to(equal(1))
                            // State must be absent so the next access triggers a fresh fetch.
                            let knownIds = localController.knownIds
                            expect(knownIds).notTo(contain("ph1"))

                            // Confirm the next explicit access does start a fetch.
                            localManager.resetPrefetchCalls()
                            localController.prefetch(ids: ["ph1"]) { result in
                                expect(result["ph1"]).to(equal(.ready))
                                expect(localManager.prefetchCallCount).to(equal(1))
                                done()
                            }
                        }
                    }
                }
            }
        }

        describe("prefetch with deadline") {
            it("returns loading for ids still in-flight when deadline elapses") {
                manager.prefetchAvailabilityAfterFetch = .ready
                manager.prefetchDelay = 0.5

                waitUntil(timeout: .seconds(5)) { done in
                    controller.prefetch(ids: ["ph1", "ph2"], deadline: 0.1) { result in
                        expect(result["ph1"]).to(equal(.loading))
                        expect(result["ph2"]).to(equal(.loading))
                        done()
                    }
                }
            }

            it("returns actual availability when fetch completes before deadline") {
                manager.prefetchAvailabilityAfterFetch = .ready
                manager.prefetchDelay = 0.05

                waitUntil(timeout: .seconds(5)) { done in
                    controller.prefetch(ids: ["ph1"], deadline: 2.0) { result in
                        expect(result["ph1"]).to(equal(.ready))
                        done()
                    }
                }
            }

            it("fires completion at most once when both fetch and deadline race") {
                manager.prefetchAvailabilityAfterFetch = .ready
                manager.prefetchDelay = 0.1

                waitUntil(timeout: .seconds(5)) { done in
                    var callCount = 0
                    controller.prefetch(ids: ["ph1"], deadline: 0.1) { _ in
                        callCount += 1
                    }
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.4) {
                        expect(callCount).to(equal(1))
                        done()
                    }
                }
            }
        }

        describe("retryableFailure outcome") {
            it("returns a complete result map when a shared in-flight id races a retryableFailure for the new id") {
                // Call 1 starts ph_b in-flight (0.3 s, succeeds).
                // Call 2 requests ph_b (already in-flight → waiter) + ph_c (new id → 2nd fetch call →
                // retryableFailure, fires synchronously before call 1 completes).
                // Without the fix, retryableFailure fires completion immediately with only {"ph_c": .loading},
                // and ph_b is never added because completionFired blocks the later waiter deliver().
                // Use ID-based failure so the result is deterministic regardless of
                // the concurrent global-queue ordering of the two manager calls.
                manager.prefetchAvailabilityAfterFetch = .ready
                manager.prefetchDelay = 0.3
                manager.retryableFailureForIds = ["ph_c"]

                waitUntil(timeout: .seconds(5)) { done in
                    controller.prefetch(ids: ["ph_b"]) { _ in }
                    controller.prefetch(ids: ["ph_b", "ph_c"]) { result in
                        expect(result.count).to(equal(2))
                        expect(result["ph_b"]).to(equal(.ready))
                        expect(result["ph_c"]).to(equal(.loading))
                        done()
                    }
                }
            }

            it("resolves prefetch result to loading and does not retain manager state") {
                manager.simulateRetryableFailure = true

                waitUntil(timeout: .seconds(3)) { done in
                    controller.prefetch(ids: ["ph1"]) { result in
                        expect(result["ph1"]).to(equal(.loading))
                        done()
                    }
                }
            }

            it("resolves an open availability waiter to timedOut immediately on retryableFailure") {
                manager.simulateRetryableFailure = true
                manager.prefetchDelay = 0.1

                waitUntil(timeout: .seconds(5)) { done in
                    controller.availability(id: "ph1", deadline: 10.0) { decision in
                        expect(decision).to(equal(.timedOut))
                        done()
                    }
                }
            }

            it("resolves multiple concurrent availability waiters to timedOut when retryableFailure arrives") {
                manager.simulateRetryableFailure = true
                manager.prefetchDelay = 0.1

                waitUntil(timeout: .seconds(5)) { done in
                    var decisions: [InAppContentBlockAvailabilityDecision] = []
                    let lock = NSLock()

                    controller.availability(id: "ph1", deadline: 10.0) { decision in
                        lock.withLock { decisions.append(decision) }
                    }
                    controller.availability(id: "ph1", deadline: 10.0) { decision in
                        lock.withLock { decisions.append(decision) }
                        if decisions.count == 2 {
                            expect(decisions).to(equal([.timedOut, .timedOut]))
                            done()
                        }
                    }
                }
            }
        }

        describe("network error during prefetch") {
            it("resolves prefetch result to empty when manager returns no data") {
                manager.simulateNetworkError = true

                waitUntil(timeout: .seconds(3)) { done in
                    Task {
                        let result = await controller.prefetch(ids: ["ph1"])
                        expect(result["ph1"]).to(equal(.empty))
                        done()
                    }
                }
            }

            it("resolves availability to timedOut when network error arrives after deadline elapses") {
                manager.simulateNetworkError = true
                manager.prefetchDelay = 0.5

                waitUntil(timeout: .seconds(5)) { done in
                    controller.availability(id: "error_ph", deadline: 0.2) { decision in
                        expect(decision).to(equal(.timedOut))
                        done()
                    }
                }
            }

            it("resolves availability to resolved empty after error if deadline has not elapsed") {
                manager.simulateNetworkError = true

                waitUntil(timeout: .seconds(5)) { done in
                    controller.availability(id: "error_ph", deadline: 2.0) { decision in
                        expect(decision).to(equal(.resolved(.empty)))
                        done()
                    }
                }
            }
        }
    }
}
