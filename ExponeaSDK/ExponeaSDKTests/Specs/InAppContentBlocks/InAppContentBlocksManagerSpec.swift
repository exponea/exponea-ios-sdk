//
//  InAppContentBlocksManagerSpec.swift.swift
//  ExponeaSDKTests
//
//  Created by Ankmara on 22.06.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class InAppContentBlocksManagerSpec: QuickSpec {

    let configuration = try! Configuration(
        projectToken: "token",
        authorization: Authorization.none,
        baseUrl: "baseUrl"
    )

    override func spec() {
        Exponea.shared.configure(with: configuration)
        let manager: InAppContentBlocksManagerType = Exponea.shared.inAppContentBlocksManager!

        it("Corrupted images") {
            let rawHtml = "<html>" +
                    "<body>" +
                    "<img src='https://upload.wikimedia.org/wikipedia/commons/9/9a/Gull_portrait_ca_usa.jpg'>" +
                    "<img src='https://upload.wikimedia.org/wikipedia/commons/9/9a/Gull_portrait_ca_usa.jpg'>" +
                    "<div data-actiontype='close' onclick='alert('hello')'>Close</div>" +
                    "<div data-link='https://example.com/1'>Action 1</div>" +
                    "<div data-link='https://example.com/2'>Action 2</div>" +
                    "</body></html>"
            let rawHtmlEmptyImages = "<html>" +
                    "<body>" +
                    "<div data-actiontype='close' onclick='alert('hello')'>Close</div>" +
                    "<div data-link='https://example.com/1'>Action 1</div>" +
                    "<div data-link='https://example.com/2'>Action 2</div>" +
                    "</body></html>"
            let rawHtmlCorruptedImage = "<html>" +
                    "<body>" +
                    "<img src='https://upload.wikimedia.org/wikipedia/commons/9/9a/Gull_portrait_ca_usssssa.jpg'>" +
                    "<div data-actiontype='close' onclick='alert('hello')'>Close</div>" +
                    "<div data-link='https://example.com/1'>Action 1</div>" +
                    "<div data-link='https://example.com/2'>Action 2</div>" +
                    "</body></html>"
            let result = manager.hasHtmlImages(html: rawHtml) // true
            let result2 = manager.hasHtmlImages(html: rawHtmlEmptyImages) // true
            let result3 = manager.hasHtmlImages(html: rawHtmlCorruptedImage) // false
            expect(result).to(beTrue())
            expect(result2).to(beTrue())
            expect(result3).to(beFalse())
        }
        
        it("check inAppContentBlocks priority") {
            let firstInAppContentBlocks = SampleInAppContentBlocks.getSampleIninAppContentBlocks(loadPriority: 1)
            let secondInAppContentBlocks = SampleInAppContentBlocks.getSampleIninAppContentBlocks(loadPriority: 2)
            let thirdInAppContentBlocks = SampleInAppContentBlocks.getSampleIninAppContentBlocks(loadPriority: 2)
            let fourthInAppContentBlocks = SampleInAppContentBlocks.getSampleIninAppContentBlocks(loadPriority: 2)
            let input = [
                firstInAppContentBlocks,
                secondInAppContentBlocks,
                thirdInAppContentBlocks,
                fourthInAppContentBlocks,
            ]
            let prioritized = manager.filterPriority(input: input)
            expect(prioritized[1]?.count).to(equal(1))
            expect(prioritized[2]?.count).toNot(equal(10))
            expect(prioritized[2]?.count).to(equal(3))
        }

        it("check TTL") {
            let ttlSeen = Date()
            let inAppContentBlocks = [SampleInAppContentBlocks.getSampleIninAppContentBlocks(personalized: .getSample(status: .ok, ttlSeen: ttlSeen))]
            let savedTags = inAppContentBlocks[0].tags ?? []
            let messagesNeeedToRefresh = inAppContentBlocks.first(where: { inAppContentBlocks in
                if let tags = inAppContentBlocks.tags, tags == savedTags,
                   let ttlSeen = inAppContentBlocks.personalizedMessage?.ttlSeen,
                   let ttl = inAppContentBlocks.personalizedMessage?.ttlSeconds,
                   inAppContentBlocks.content == nil {
                    return Date() > ttlSeen.addingTimeInterval(TimeInterval(ttl))
                }
                return false
            })
            expect(messagesNeeedToRefresh).toEventually(beNil(), timeout: .seconds(2))
            var messagesNeeedToRefreshTrue: InAppContentBlockResponse?
            waitUntil(timeout: .seconds(6)) { done in
                DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                    messagesNeeedToRefreshTrue = inAppContentBlocks.first(where: { inAppContentBlocks in
                        if let tag = inAppContentBlocks.tags, tag == savedTags,
                           let ttlSeen = inAppContentBlocks.personalizedMessage?.ttlSeen,
                           let ttl = inAppContentBlocks.personalizedMessage?.ttlSeconds,
                           inAppContentBlocks.content == nil {
                            return Date() > ttlSeen.addingTimeInterval(TimeInterval(ttl))
                        }
                        return false
                    })
                    done()
                }
            }
            expect(messagesNeeedToRefreshTrue).toEventuallyNot(beNil(), timeout: .seconds(1))
        }

        it("filter - always") {
            var inAppContentBlocks = SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                id: "filter - always - msg123 - \(UUID().uuidString)",
                personalized: .getSample(
                    status: .ok,
                    ttlSeen: Date()
                )
            )
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                manager.updateDisplayedState(for: inAppContentBlocks.id)
                manager.updateInteractedState(for: inAppContentBlocks.id)
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
                manager.updateDisplayedState(for: inAppContentBlocks.id)
                manager.updateInteractedState(for: inAppContentBlocks.id)
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                manager.updateDisplayedState(for: inAppContentBlocks.id)
                manager.updateInteractedState(for: inAppContentBlocks.id)
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 2.5) {
                manager.updateDisplayedState(for: inAppContentBlocks.id)
                manager.updateInteractedState(for: inAppContentBlocks.id)
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
                manager.updateDisplayedState(for: inAppContentBlocks.id)
                manager.updateInteractedState(for: inAppContentBlocks.id)
            }
            expect(manager.getFilteredMessage(message: inAppContentBlocks)).toEventually(beTrue(), timeout: .seconds(4))
        }

        it("filter - interaction") {
            var inAppContentBlocks = SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                id: "filter - interaction - msg123 - \(UUID().uuidString)",
                frequency: .untilVisitorInteracts,
                personalized: .getSample(
                    status: .ok,
                    ttlSeen: Date()
                )
            )
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                manager.updateDisplayedState(for: inAppContentBlocks.id)
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
                manager.updateDisplayedState(for: inAppContentBlocks.id)
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                manager.updateDisplayedState(for: inAppContentBlocks.id)
            }
            expect(manager.getFilteredMessage(message: inAppContentBlocks)).toEventually(beTrue(), timeout: .seconds(3))
            DispatchQueue.global().asyncAfter(deadline: .now() + 3.1) {
                manager.updateDisplayedState(for: inAppContentBlocks.id)
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 3.5) {
                manager.updateDisplayedState(for: inAppContentBlocks.id)
                manager.updateInteractedState(for: inAppContentBlocks.id)
            }
            expect(manager.getFilteredMessage(message: inAppContentBlocks)).toEventually(beFalse(), timeout: .seconds(4))
        }

        it("filter - seen") {
            var inAppContentBlocks = SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                id: "filter - seen - msg123 - \(UUID().uuidString)",
                frequency: .onlyOnce,
                personalized: .getSample(
                    status: .ok,
                    ttlSeen: Date()
                )
            )
            expect(manager.getFilteredMessage(message: inAppContentBlocks)).toEventually(beTrue(), timeout: .seconds(3))
            DispatchQueue.global().asyncAfter(deadline: .now() + 3.5) {
                manager.updateDisplayedState(for: inAppContentBlocks.id)
                manager.updateInteractedState(for: inAppContentBlocks.id)
            }
            expect(manager.getFilteredMessage(message: inAppContentBlocks)).toEventually(beFalse(), timeout: .seconds(4))
        }

        it("prefetch") {
            let inAppContentBlocks = [
                SampleInAppContentBlocks.getSampleIninAppContentBlocks(placeholders: ["ph1"], personalized: .getSample(status: .ok, ttlSeen: Date())),
                SampleInAppContentBlocks.getSampleIninAppContentBlocks(placeholders: ["ph1"], personalized: .getSample(status: .ok, ttlSeen: Date())),
                SampleInAppContentBlocks.getSampleIninAppContentBlocks(placeholders: ["ph1"], personalized: .getSample(status: .ok, ttlSeen: Date())),
                SampleInAppContentBlocks.getSampleIninAppContentBlocks(placeholders: ["ph2"], personalized: .getSample(status: .ok, ttlSeen: Date())),
            ]
            expect(manager.prefetchPlaceholdersWithIds(input: inAppContentBlocks, ids: ["ph1"]).count).to(be(3))
            expect(manager.prefetchPlaceholdersWithIds(input: inAppContentBlocks, ids: ["ph2"]).count).to(be(1))
            expect(manager.prefetchPlaceholdersWithIds(input: inAppContentBlocks, ids: ["ph1", "ph2"]).count).to(be(4))
            expect(manager.prefetchPlaceholdersWithIds(input: inAppContentBlocks, ids: [""]).count).to(be(0))
        }

        it("queue") {
            var inAppContentBlocks = SampleInAppContentBlocks.getSampleIninAppContentBlocks(frequency: .onlyOnce, personalized: .getSample(status: .ok, ttlSeen: Date()))
            var completionValue: Int = 0
            waitUntil(timeout: .seconds(25)) { done in
                for i in 0..<11 {
                    manager.refreshStaticViewContent(staticQueueData: .init(tag: inAppContentBlocks.tags?.first ?? 0, placeholderId: inAppContentBlocks.name, completion: { _ in
                        completionValue = i
                        if i == 10 {
                            done()
                        }
                    }))
                }
            }
            expect(completionValue).to(be(10))
        }
    }
}
