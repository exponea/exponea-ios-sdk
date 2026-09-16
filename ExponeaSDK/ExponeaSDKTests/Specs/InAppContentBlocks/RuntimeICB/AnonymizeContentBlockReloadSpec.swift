//
//  AnonymizeContentBlockReloadSpec.swift
//  ExponeaSDKTests
//
//  Copyright © 2026 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK
@testable import ExponeaSDKShared

final class AnonymizeContentBlockReloadSpec: QuickSpec {
    override func spec() {
        describe("customer-change catalog lifecycle") {
            var manager: MockInAppContentBlocksManager!
            var controller: RuntimeInContentBlockController!

            beforeEach {
                IntegrationManager.shared.isStopped = false
                let database = try! DatabaseManager()
                try! database.clear()

                let exponea = ExponeaInternal()
                Exponea.shared = exponea
                Exponea.shared.configure(
                    Exponea.ProjectSettings(
                        projectToken: "mock-token",
                        authorization: .token("mock-token")
                    ),
                    pushNotificationTracking: .disabled,
                    inAppContentBlocksPlaceholders: ["configured_ph"],
                    flushingSetup: Exponea.FlushingSetup(mode: .manual)
                )

                manager = MockInAppContentBlocksManager()
                manager.loadsCatalogOnFirstUse = true
                controller = RuntimeInContentBlockController(manager: manager)
                exponea.inAppContentBlocksManager = manager
                exponea.concreteICBController = controller
            }

            it("loads the catalog and prefetches configured placeholders on anonymize, without refetching remembered ids") {
                manager.prefetchAvailabilityAfterFetch = .ready

                waitUntil(timeout: .seconds(10)) { done in
                    Task {
                        _ = await controller.prefetch(ids: ["remembered_ph"])
                        manager.resetPrefetchCalls()

                        Exponea.shared.anonymize {
                            expect(manager.anonymizeCallCount).to(equal(1))
                            expect(manager.catalogLoadCallCount).to(equal(1))
                            expect(manager.prefetchCallCount).to(equal(1))
                            expect(manager.prefetchedIds).to(equal(["configured_ph"]))
                            expect(controller.knownIds).to(beEmpty())
                            done()
                        }
                    }
                }
            }

            it("reuses the catalog loaded by anonymize and personalizes only the controller-requested id") {
                manager.prefetchAvailabilityAfterFetch = .ready

                waitUntil(timeout: .seconds(10)) { done in
                    Task {
                        _ = await controller.prefetch(ids: ["remembered_ph"])
                        manager.resetPrefetchCalls()

                        Exponea.shared.anonymize {
                            Task<Void, Never> {
                                let result = await controller.prefetch(ids: ["requested_ph"])
                                expect(result["requested_ph"]).to(equal(.ready))
                                expect(manager.catalogLoadCallCount).to(equal(1))
                                expect(manager.prefetchedIds).to(contain("configured_ph", "requested_ph"))
                                expect(manager.prefetchedIds).notTo(contain("remembered_ph"))
                                done()
                            }
                        }
                    }
                }
            }

            it("clears ICB cache and controller availability state but does not reload catalog on customer identity change") {
                manager.prefetchAvailabilityAfterFetch = .ready

                waitUntil(timeout: .seconds(5)) { done in
                    Task {
                        _ = await controller.prefetch(ids: ["remembered_ph"])
                        manager.resetPrefetchCalls()

                        Exponea.shared.identifyCustomer(
                            context: CustomerIdentity(customerIds: ["registered": "new-customer"]),
                            properties: [:],
                            timestamp: nil
                        )

                        try await Task.sleep(nanoseconds: 100_000_000)

                        expect(manager.anonymizeCallCount).to(equal(0))
                        expect(manager.catalogLoadCallCount).to(equal(0))
                        expect(manager.prefetchedIds).to(beEmpty())
                        expect(controller.knownIds).to(beEmpty())

                        // Manager-level personalised cache must also be cleared: a re-prefetch of
                        // the same placeholder after identity change must hit the network (prefetchCallCount == 1)
                        // rather than coasting on the previous customer's cached content.
                        let result = await controller.prefetch(ids: ["remembered_ph"])
                        expect(result["remembered_ph"]).to(equal(.ready))
                        expect(manager.prefetchCallCount).to(equal(1))
                        done()
                    }
                }
            }
        }
    }
}
