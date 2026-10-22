//
//  SegmentationSpec.swift
//  ExponeaSDKTests
//
//  Created by Ankmara on 24.04.2024.
//  Copyright © 2024 Exponea. All rights reserved.
//

import Quick
import Nimble

@testable import ExponeaSDK

class SegmentationSpec: QuickSpec {

    let configuration = try! Configuration(
        projectToken: "token",
        authorization: Authorization.none,
        baseUrl: "baseUrl"
    )

    override func spec() {
        var manager: SegmentationManagerType?
        
        beforeEach {
            // Reset Exponea shared instance to ensure clean state
            Exponea.shared = ExponeaInternal()
            Exponea.shared.configure(with: self.configuration)
            manager = Exponea.shared.segmentationManager
            expect(manager).notTo(beNil(), description: "SegmentationManager should be available after configuration")
            manager?.removeAll()
        }

        it("union segments") {
            guard let manager = manager else {
                fail("Manager should not be nil")
                return
            }
            let discovery: SegmentCategory = .discovery(data: [
                .init(id: "id1", segmentationId: "segmentationId1"),
                .init(id: "id2", segmentationId: "segmentationId2"),
                .init(id: "id2", segmentationId: "segmentationId3")
            ])
            let content: SegmentCategory = .content(data: [
                .init(id: "id1", segmentationId: "segmentationId1")
            ])
            let merchandising: SegmentCategory = .merchandising(data: [
                .init(id: "id2", segmentationId: "segmentationId2"),
                .init(id: "id5", segmentationId: "segmentationId5"),
                .init(id: "id1", segmentationId: "segmentationId1")
            ])
            let fetch = [discovery, content]
            let cache = [content, merchandising]
            let unionSegments = manager.unionSegments(fetchedCategories: fetch, cachedCategories: cache, newbies: [])
            // discovery + content + merchandising
            expect(unionSegments.count).to(equal(3))
            var numberOfDiscovery = 0
            var numberOfContent = 0
            var numberOfMerchandising = 0
            for category in unionSegments {
                switch category {
                case let .discovery(data):
                    numberOfDiscovery = data.count
                case let .content(data):
                    numberOfContent = data.count
                case let .merchandising(data):
                    numberOfMerchandising = data.count
                default: continue
                }
            }
            expect(numberOfDiscovery).to(equal(3))  // is in Fetch
            expect(numberOfContent).to(equal(1))  // is in Fetch
            expect(numberOfMerchandising).to(equal(0))  // is only in cache, so Fetch is empty
        }

        it("callbacks") {
            guard let manager = manager else {
                fail("Manager should not be nil")
                return
            }
            var totalFiredCallback = 0
            var totalFiredNewbies = 0

            waitUntil(timeout: .seconds(3)) { done in
                manager.addCallback(callbackData: .init(category: .discovery(), isIncludeFirstLoad: false, onNewData: { _ in
                    totalFiredCallback += 1
                }))
                manager.addCallback(callbackData: .init(category: .discovery(), isIncludeFirstLoad: true, onNewData: { segments in
                    if segments.contains(where: { $0.id == "new" }) {
                        totalFiredNewbies += 1
                    } else {
                        totalFiredCallback += 1
                    }
                }))
                manager.addCallback(callbackData: .init(category: .discovery(), isIncludeFirstLoad: true, onNewData: { segments in
                    if segments.contains(where: { $0.id == "new" }) {
                        totalFiredNewbies += 1
                    } else {
                        totalFiredCallback += 1
                    }
                }))
                manager.addCallback(callbackData: .init(category: .discovery(), isIncludeFirstLoad: false, onNewData: { _ in
                    totalFiredCallback += 1
                }))

                expect(manager.getNewbies().count).to(equal(2))
                expect(manager.getCallbacks().count).to(equal(4))

                manager.getNewbies().forEach { segment in
                    segment.fireBlock(category: [
                        .init(id: "new", segmentationId: "1"),
                        .init(id: "new", segmentationId: "2"),
                    ])
                }

                manager.getCallbacks().forEach { segment in
                    segment.fireBlock(category: [
                        .init(id: "1", segmentationId: "1"),
                        .init(id: "2", segmentationId: "2"),
                    ])
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: done)
            }

            expect(totalFiredCallback).to(equal(4))
            expect(totalFiredNewbies).to(equal(2))
        }

        it("remove and anonymize") {
            guard let manager = manager else {
                fail("Manager should not be nil")
                return
            }
            manager.removeAll()
            let callback: SegmentCallbackData = .init(category: .discovery(), isIncludeFirstLoad: false) { _ in }
            let callback2: SegmentCallbackData = .init(category: .discovery(), isIncludeFirstLoad: true) { _ in }
            manager.addCallback(callbackData: callback)
            manager.addCallback(callbackData: callback2)
            manager.addCallback(callbackData: callback2)
            manager.addCallback(callbackData: callback2)

            manager.removeCallback(callbackData: callback)

            expect(manager.getCallbacks().count).to(equal(3))
            expect(manager.getNewbies().count).to(equal(3))

            manager.removeCallback(callbackData: callback2)
            expect(manager.getNewbies().count).to(equal(0))
            expect(manager.getCallbacks().count).to(equal(0))

            manager.addCallback(callbackData: callback)
            manager.addCallback(callbackData: callback2)

            manager.anonymize()
            expect(manager.getNewbies().count).to(equal(0))
            expect(manager.getCallbacks().count).to(equal(2))
        }

        it("synchronize") {
            guard let manager = manager else {
                fail("Manager should not be nil")
                return
            }
            @SegmentationStoring  var storedSegmentations: SegmentStore?
            let segment: SegmentDataDTO = .init(categories: [.discovery(data: [.init(id: "1", segmentationId: "1")])])
            let segment2: SegmentDataDTO = .init(categories: [.discovery(data: [.init(id: "2", segmentationId: "1")])])
            let segment3: SegmentDataDTO = .init(categories: [.discovery(data: [.init(id: "1", segmentationId: "1"), .init(id: "2", segmentationId: "2"), .init(id: "2", segmentationId: "3")])])
            storedSegmentations = .init(customerIds: ["customer": "test"], segmentData: segment)

            // Same customer from store and config. Store and fetch are equal - reult is 0
            let result = manager.synchronizeSegments(customerIds: ["customer": "test"], input: segment)
            expect(result.count).to(equal(0))

            // Same customer from store and config. Store and fetch are not equal - reult is 1
            let result2 = manager.synchronizeSegments(customerIds: ["customer": "test"], input: segment2)
            expect(result2.count).to(equal(1))
            switch result2.first {
            case let .discovery(data):
                expect(data.count).to(equal(1))
            default: break
            }

            // Not same customer from store and config. Return all new data - result is 3
            let result3 = manager.synchronizeSegments(customerIds: ["customer": "oldText"], input: segment3)
            expect(result3.count).to(equal(1))
            switch result3.first {
            case let .discovery(data):
                expect(data.count).to(equal(3))
            default: break
            }

            storedSegmentations = .init(customerIds: ["customer": "test"], segmentData: .init(categories: [.discovery(data: [.init(id: "id", segmentationId: "id")])]))
            let result4 = manager.synchronizeSegments(customerIds: ["customer": "oldText"], input: .init(categories: []))
            expect(result4.count).to(equal(0))
        }

        it("lifetime") {
            let manualDTO: ManualSegmentsCacheDTO = .init(
                timestamp: Date().timeIntervalSince1970,
                data: .init(categories: [.content()]),
                assignedCustomer: ["user": "123"]
            )
            expect(manualDTO.isWithinTime).to(beTrue())
            var isExpired = false
            waitUntil(timeout: .seconds(8)) { done in
                DispatchQueue.global().asyncAfter(deadline: .now() + 5.5) {
                    isExpired = !manualDTO.isWithinTime
                    done()
                }
            }
            expect(isExpired).to(beTrue())
        }

        describe("SegmentDataDTO decoding") {
            func decode(_ json: String) throws -> [SegmentCategory] {
                try JSONDecoder().decode(SegmentDataDTO.self, from: Data(json.utf8)).categories
            }

            it("decodes an empty object to no categories") {
                expect(try decode("{}")).to(beEmpty())
            }

            it("decodes an empty category") {
                let categories = try decode(#"{"discovery":[]}"#)
                expect(categories.count).to(equal(1))
                guard case let .discovery(data) = categories.first else { return fail("Expected discovery") }
                expect(data).to(beEmpty())
            }

            it("decodes segments of a category") {
                let categories = try decode(#"{"discovery":[{"id":"d1","segmentation_id":"s1"}]}"#)
                guard case let .discovery(data) = categories.first else { return fail("Expected discovery") }
                expect(data).to(equal([.init(id: "d1", segmentationId: "s1")]))
            }
        }

        describe("manual fetch") {
            // Mirrors SegmentsManagerImpl.fetchSegmentsManually of the Android SDK.
            let discovery: [SegmentDTO] = [.init(id: "d1", segmentationId: "s1")]
            let content: [SegmentDTO] = [.init(id: "c1", segmentationId: "s2")]
            let noSegments: [[SegmentDTO]] = [[]]
            var repository: MockRepository!
            var manualManager: ManualSegmentationManager!
            var customerIds: [String: String] = [:]

            beforeEach {
                repository = MockRepository(configuration: self.configuration)
                repository.fetchLinkIdsResult = .success
                Exponea.shared.repository = repository
                customerIds = ["cookie": "cookie-1"]
                manualManager = ManualSegmentationManager()
                manualManager.customerIdsProvider = { customerIds }
            }

            afterEach {
                IntegrationManager.shared.isStopped = false
            }

            // Collects every result delivered for one getSegments call, so a missing or a
            // repeated callback both fail the expectation.
            func fetch(_ category: SegmentCategory, force: Bool = true) -> [[SegmentDTO]] {
                var results: [[SegmentDTO]] = []
                waitUntil(timeout: .seconds(3)) { done in
                    manualManager.getSegments(category: category, force: force) { segments in
                        results.append(segments)
                        if results.count == 1 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: done)
                        }
                    }
                }
                return results
            }

            it("returns an empty list when the response has no segments") {
                // The backend answers `{}` for a customer without segments.
                repository.fetchSegmentationsResult = .success(.init(categories: []))
                expect(fetch(.discovery())).to(equal(noSegments))
            }

            it("returns only the requested category") {
                repository.fetchSegmentationsResult = .success(
                    .init(categories: [.content(data: content), .discovery(data: discovery)])
                )
                expect(fetch(.discovery())).to(equal([discovery]))
                expect(fetch(.merchandising())).to(equal(noSegments))
            }

            it("returns an empty list on failure and fetches again next time") {
                repository.fetchSegmentationsResult = .failure(RepositoryError.connectionError)
                expect(fetch(.discovery())).to(equal(noSegments))

                repository.fetchSegmentationsResult = .success(.init(categories: [.discovery(data: discovery)]))
                expect(fetch(.discovery())).to(equal([discovery]))
            }

            it("serves only the requested category from a fresh cache") {
                repository.fetchSegmentationsResult = .success(
                    .init(categories: [.content(data: content), .discovery(data: discovery)])
                )
                expect(fetch(.discovery())).to(equal([discovery]))

                repository.fetchSegmentationsResult = nil
                expect(fetch(.discovery(), force: false)).to(equal([discovery]))
                expect(fetch(.merchandising(), force: false)).to(equal(noSegments))
                expect(repository.getSegmentationsCookies.count).to(equal(1))
            }

            it("returns an empty list without fetching when the SDK is stopped") {
                repository.fetchSegmentationsResult = .success(.init(categories: [.discovery(data: discovery)]))
                IntegrationManager.shared.isStopped = true
                expect(fetch(.discovery())).to(equal(noSegments))
                expect(repository.getSegmentationsCookies).to(beEmpty())
            }

            it("returns an empty list without a cookie") {
                customerIds = [:]
                repository.fetchSegmentationsResult = .success(.init(categories: [.discovery(data: discovery)]))
                expect(fetch(.discovery())).to(equal(noSegments))
                expect(repository.getSegmentationsCookies).to(beEmpty())
            }

            it("links external IDs once per customer before fetching") {
                customerIds = ["cookie": "cookie-1", "registered": "user@example.com"]
                repository.fetchSegmentationsResult = .success(.init(categories: [.discovery(data: discovery)]))
                expect(fetch(.discovery())).to(equal([discovery]))
                expect(fetch(.discovery())).to(equal([discovery]))
                expect(repository.getLinkIdsCount).to(equal(1))
                expect(repository.getSegmentationsCookies.count).to(equal(2))
            }

            it("does not log customer ID values when linking fails") {
                customerIds = ["cookie": "cookie-1", "registered": "user@example.com"]
                repository.fetchLinkIdsResult = .failure(RepositoryError.connectionError)
                var logs: [String] = []
                let hookId = Exponea.logger.addLogHook { logs.append($0) }
                defer { Exponea.logger.removeLogHook(with: hookId) }
                expect(fetch(.discovery())).to(equal(noSegments))
                expect(logs.contains { $0.contains("merge failed") }).to(beTrue())
                expect(logs.contains { $0.contains("user@example.com") || $0.contains("cookie-1") }).to(beFalse())
            }

            it("returns an empty list for a real `{}` response") {
                // The exact scenario from the ticket: HTTP 200 with an empty JSON object.
                var requestedUrl: URL?
                NetworkStubbing.stubNetwork(
                    forIntegrationType: self.configuration.integrationConfig.type,
                    withStatusCode: 200,
                    withResponseData: Data("{}".utf8),
                    withRequestHook: { requestedUrl = $0.url }
                )
                defer { NetworkStubbing.unstubNetwork() }
                Exponea.shared.repository = ServerRepository(configuration: self.configuration)
                expect(fetch(.discovery())).to(equal(noSegments))
                expect(requestedUrl?.absoluteString).to(contain("/segments?cookie=cookie-1"))
                // The cache is only stored when the body decoded successfully.
                expect(manualManager.cache?.data.categories).to(beEmpty())
            }

            it("returns an empty list without fetching when linking fails") {
                customerIds = ["cookie": "cookie-1", "registered": "user@example.com"]
                repository.fetchLinkIdsResult = .failure(RepositoryError.connectionError)
                repository.fetchSegmentationsResult = .success(.init(categories: [.discovery(data: discovery)]))
                expect(fetch(.discovery())).to(equal(noSegments))
                expect(repository.getSegmentationsCookies).to(beEmpty())
            }

            it("fetches again with the new cookie when the customer changes meanwhile") {
                repository.fetchSegmentationsResult = .success(.init(categories: [.discovery(data: discovery)]))
                repository.onGetSegmentations = { _ in
                    customerIds = ["cookie": "cookie-2"]
                }
                expect(fetch(.discovery())).to(equal([discovery]))
                expect(repository.getSegmentationsCookies).to(equal(["cookie-1", "cookie-2"]))
            }

            it("answers waiting callers with an empty list on anonymize") {
                var results: [[SegmentDTO]] = []
                waitUntil(timeout: .seconds(3)) { done in
                    // The fetch never completes, so only anonymize can answer.
                    manualManager.getSegments(category: .discovery(), force: true) { segments in
                        results.append(segments)
                        done()
                    }
                    manualManager.anonymize()
                }
                expect(results).to(equal(noSegments))
            }
        }
    }
}
