//
//  RuntimeInContentBlockControllerLifecycleSpec.swift
//  ExponeaSDKTests
//
//  Copyright © 2026 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import ExponeaSDK

class RuntimeInContentBlockControllerLifecycleSpec: QuickSpec {
    override func spec() {
        var manager: MockInAppContentBlocksManager!
        var controller: RuntimeInContentBlockController!

        beforeEach {
            manager = MockInAppContentBlocksManager()
            controller = RuntimeInContentBlockController(manager: manager)
        }

        describe("knownIds") {
            it("is empty on a fresh controller") {
                expect(controller.knownIds).to(beEmpty())
            }

            it("reflects ids after prefetch") {
                manager.prefetchAvailabilityAfterFetch = .ready

                waitUntil(timeout: .seconds(3)) { done in
                    Task {
                        _ = await controller.prefetch(ids: ["ph1", "ph2"])
                        expect(controller.knownIds).to(contain("ph1", "ph2"))
                        done()
                    }
                }
            }

            it("reflects ids implicitly fetched via availability") {
                manager.prefetchAvailabilityAfterFetch = .ready

                waitUntil(timeout: .seconds(3)) { done in
                    controller.availability(id: "implicit_ph", deadline: 2.0) { _ in
                        expect(controller.knownIds).to(contain("implicit_ph"))
                        done()
                    }
                }
            }
        }

        describe("stopIntegration") {
            it("drains all pending availability waiters as timedOut before their deadlines") {
                manager.prefetchAvailabilityAfterFetch = .ready
                manager.prefetchDelay = 5.0

                waitUntil(timeout: .seconds(3)) { done in
                    var received: InAppContentBlockAvailabilityDecision?
                    controller.availability(id: "ph1", deadline: 10.0) { decision in
                        received = decision
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        controller.stopIntegration()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            expect(received).to(equal(.timedOut))
                            done()
                        }
                    }
                }
            }

            it("drains multiple waiters simultaneously") {
                manager.prefetchDelay = 5.0

                waitUntil(timeout: .seconds(3)) { done in
                    var decisions: [InAppContentBlockAvailabilityDecision] = []

                    controller.availability(id: "ph1", deadline: 10.0) { decisions.append($0) }
                    controller.availability(id: "ph2", deadline: 10.0) { decisions.append($0) }
                    controller.availability(id: "ph3", deadline: 10.0) { decisions.append($0) }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        controller.stopIntegration()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            expect(decisions).to(haveCount(3))
                            expect(decisions).to(allPass(equal(.timedOut)))
                            done()
                        }
                    }
                }
            }

            it("resolves queued prefetch waiters as loading when called mid-fetch") {
                manager.prefetchAvailabilityAfterFetch = .ready
                manager.prefetchDelay = 5.0

                waitUntil(timeout: .seconds(3)) { done in
                    var secondResult: [String: InAppContentBlockAvailability]?

                    controller.prefetch(ids: ["ph1"]) { _ in }
                    controller.prefetch(ids: ["ph1"]) { result in
                        secondResult = result
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        controller.stopIntegration()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            expect(secondResult).to(equal(["ph1": .loading]))
                            done()
                        }
                    }
                }
            }

            it("is a no-op when there are no pending waiters") {
                controller.stopIntegration()
                expect(controller.knownIds).to(beEmpty())
            }

            it("makes subsequent availability calls arm fresh waiters") {
                manager.prefetchAvailabilityAfterFetch = .ready
                manager.prefetchDelay = 5.0

                waitUntil(timeout: .seconds(5)) { done in
                    controller.stopIntegration()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        manager.prefetchDelay = 0
                        controller.availability(id: "ph1", deadline: 2.0) { decision in
                            expect(decision).to(equal(.resolved(.ready)))
                            done()
                        }
                    }
                }
            }

            it("clears known ids so same-instance access starts a fresh fetch") {
                manager.prefetchAvailabilityAfterFetch = .ready

                waitUntil(timeout: .seconds(5)) { done in
                    Task {
                        _ = await controller.prefetch(ids: ["ph1"])
                        controller.stopIntegration()

                        try await Task.sleep(nanoseconds: 100_000_000)
                        expect(controller.knownIds).to(beEmpty())

                        manager.anonymize()
                        manager.resetPrefetchCalls()
                        let decision = await controller.availability(id: "ph1", deadline: 2.0)

                        expect(decision).to(equal(.resolved(.ready)))
                        expect(manager.prefetchCallCount).to(equal(1))
                        done()
                    }
                }
            }
        }

        describe("anonymize lifecycle") {
            it("drops cached terminal states without refetching remembered ids") {
                manager.prefetchAvailabilityAfterFetch = .ready

                waitUntil(timeout: .seconds(5)) { done in
                    Task {
                        _ = await controller.prefetch(ids: ["ph1", "ph2"])
                        manager.resetPrefetchCalls()

                        controller.prepareForAnonymize()
                        manager.anonymize()

                        expect(controller.knownIds).to(beEmpty())
                        expect(manager.prefetchCallCount).to(equal(0))
                        done()
                    }
                }
            }

            it("fetches only the id requested by first use") {
                manager.prefetchAvailabilityAfterFetch = .ready

                waitUntil(timeout: .seconds(5)) { done in
                    Task {
                        _ = await controller.prefetch(ids: ["ph1", "ph2"])
                        manager.resetPrefetchCalls()

                        controller.prepareForAnonymize()
                        manager.anonymize()

                        let decision = await controller.availability(id: "ph1", deadline: 1.0)
                        expect(decision).to(equal(.resolved(.ready)))
                        expect(manager.prefetchCallCount).to(equal(1))
                        expect(manager.prefetchedIds).to(equal(["ph1"]))
                        done()
                    }
                }
            }

            it("keeps catalog failure retryable instead of caching empty") {
                manager.loadsCatalogOnFirstUse = true
                manager.catalogLoadSucceeds = false

                waitUntil(timeout: .seconds(5)) { done in
                    Task {
                        controller.prepareForCustomerChange()
                        manager.anonymize()

                        let first = await controller.prefetch(ids: ["ph1"])
                        expect(first["ph1"]).to(equal(.loading))
                        expect(manager.catalogLoadCallCount).to(equal(1))

                        manager.catalogLoadSucceeds = true
                        manager.prefetchAvailabilityAfterFetch = .ready
                        let second = await controller.prefetch(ids: ["ph1"])

                        expect(second["ph1"]).to(equal(.ready))
                        expect(manager.catalogLoadCallCount).to(equal(2))
                        done()
                    }
                }
            }

        }

        describe("eager invalidation of all known ids") {
            it("triggers a refetch for every known id") {
                manager.prefetchAvailabilityAfterFetch = .ready

                waitUntil(timeout: .seconds(3)) { done in
                    Task {
                        _ = await controller.prefetch(ids: ["ph1", "ph2"])
                        manager.resetPrefetchCalls()

                        let known = controller.knownIds
                        controller.invalidate(ids: known, reason: "lifecycle_test", mode: .eager)

                        try await Task.sleep(nanoseconds: 200_000_000)

                        expect(manager.invalidatedPlaceholderIds.last).to(contain("ph1", "ph2"))
                        expect(manager.prefetchCallCount).to(equal(1))
                        done()
                    }
                }
            }

            it("restores ready state for all ids") {
                manager.prefetchAvailabilityAfterFetch = .ready

                waitUntil(timeout: .seconds(3)) { done in
                    Task {
                        _ = await controller.prefetch(ids: ["ph1"])
                        manager.resetPrefetchCalls()

                        controller.invalidate(
                            ids: controller.knownIds,
                            reason: "lifecycle_test",
                            mode: .eager
                        )
                        try await Task.sleep(nanoseconds: 200_000_000)

                        let result = await controller.prefetch(ids: ["ph1"])
                        expect(result["ph1"]).to(equal(.ready))
                        expect(manager.prefetchCallCount).to(equal(1))
                        done()
                    }
                }
            }

            it("is a no-op when no ids are known") {
                controller.invalidate(
                    ids: controller.knownIds,
                    reason: "lifecycle_test",
                    mode: .eager
                )
                expect(manager.invalidatedPlaceholderIds).to(beEmpty())
            }
        }
    }
}
