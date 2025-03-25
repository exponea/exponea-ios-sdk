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
        Exponea.shared.configure(with: configuration)
        let manager: SegmentationManagerType = Exponea.shared.segmentationManager!

        it("union segments") {
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
            waitUntil(timeout: .seconds(6)) { done in
                DispatchQueue.global().asyncAfter(deadline: .now() + 5.5) {
                    isExpired = !manualDTO.isWithinTime
                    done()
                }
            }
            expect(isExpired).to(beTrue())
        }
    }
}
