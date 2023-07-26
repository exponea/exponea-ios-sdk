//
//  InlineManagerSpec.swift
//  ExponeaSDKTests
//
//  Created by Ankmara on 22.06.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class InlineManagerSpec: QuickSpec {

    let configuration = try! Configuration(
        projectToken: "token",
        authorization: Authorization.none,
        baseUrl: "baseUrl"
    )
    var urlOpener: MockUrlOpener!
    var trackingConsentManager: TrackingConsentManagerType!
    var trackingManager: MockTrackingManager!
    var repository: MockRepository!

    override func spec() {
        let manager: InlineMessageManagerType = InlineMessageManager()

        beforeEach {
            self.repository = MockRepository(configuration: self.configuration)
            self.repository.fetchInlineResult = Result.success(
                .init(data: [
                    .getSample(status: .ok, ttlSeen: Date())
                ])
            )
            self.urlOpener = MockUrlOpener()
            self.trackingManager = MockTrackingManager(onEventCallback: { event, dateType in
                
            })
            self.trackingConsentManager = TrackingConsentManager(
                trackingManager: self.trackingManager
            )
        }
        
        it("check inline priority") {
            let firstInline = SampleInlineMessage.getSampleIninlineMessage(loadPriority: 1)
            let secondInline = SampleInlineMessage.getSampleIninlineMessage(loadPriority: 2)
            let thirdInline = SampleInlineMessage.getSampleIninlineMessage(loadPriority: 2)
            let fourthInline = SampleInlineMessage.getSampleIninlineMessage(loadPriority: 2)
            let input = [
                firstInline,
                secondInline,
                thirdInline,
                fourthInline,
            ]
            let prioritized = manager.filterPriority(input: input)
            expect(prioritized[1]?.count).to(equal(1))
            expect(prioritized[2]?.count).toNot(equal(10))
            expect(prioritized[2]?.count).to(equal(3))
        }

        it("check TTL") {
            let ttlSeen = Date()
            let inline = [SampleInlineMessage.getSampleIninlineMessage(personalized: .getSample(status: .ok, ttlSeen: ttlSeen))]
            let savedTags = inline[0].tags ?? []
            let messagesNeeedToRefresh = inline.first(where: { inlineMessage in
                if let tags = inlineMessage.tags, tags == savedTags,
                   let ttlSeen = inlineMessage.personalizedMessage?.ttlSeen,
                   let ttl = inlineMessage.personalizedMessage?.ttlSeconds,
                   inlineMessage.content == nil {
                    return Date() > ttlSeen.addingTimeInterval(TimeInterval(ttl))
                }
                return false
            })
            expect(messagesNeeedToRefresh).toEventually(beNil(), timeout: .seconds(2))
            var messagesNeeedToRefreshTrue: InlineMessageResponse?
            waitUntil(timeout: .seconds(6)) { done in
                DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                    messagesNeeedToRefreshTrue = inline.first(where: { inlineMessage in
                        if let tag = inlineMessage.tags, tag == savedTags,
                           let ttlSeen = inlineMessage.personalizedMessage?.ttlSeen,
                           let ttl = inlineMessage.personalizedMessage?.ttlSeconds,
                           inlineMessage.content == nil {
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
            var inline = SampleInlineMessage.getSampleIninlineMessage(personalized: .getSample(status: .ok, ttlSeen: Date()))
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                inline.displayState = .init(displayed: Date(), interacted: Date())
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
                inline.displayState = .init(displayed: Date(), interacted: Date())
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                inline.displayState = .init(displayed: Date(), interacted: Date())
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 2.5) {
                inline.displayState = .init(displayed: Date(), interacted: Date())
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
                inline.displayState = .init(displayed: Date(), interacted: Date())
            }
            expect(manager.getFilteredMessage(message: inline)).toEventually(beTrue(), timeout: .seconds(4))
        }

        it("filter - interaction") {
            var inline = SampleInlineMessage.getSampleIninlineMessage(frequency: .untilVisitorInteracts, personalized: .getSample(status: .ok, ttlSeen: Date()))
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                inline.displayState = .init(displayed: Date(), interacted: nil)
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
                inline.displayState = .init(displayed: Date(), interacted: nil)
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                inline.displayState = .init(displayed: Date(), interacted: nil)
            }
            expect(manager.getFilteredMessage(message: inline)).toEventually(beTrue(), timeout: .seconds(3))
            DispatchQueue.global().asyncAfter(deadline: .now() + 3.1) {
                inline.displayState = .init(displayed: Date(), interacted: nil)
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 3.5) {
                inline.displayState = .init(displayed: Date(), interacted: Date())
            }
            expect(manager.getFilteredMessage(message: inline)).toEventually(beFalse(), timeout: .seconds(4))
        }

        it("filter - seen") {
            var inline = SampleInlineMessage.getSampleIninlineMessage(frequency: .onlyOnce, personalized: .getSample(status: .ok, ttlSeen: Date()))
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                inline.displayState = .init(displayed: nil, interacted: nil)
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
                inline.displayState = .init(displayed: nil, interacted: nil)
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                inline.displayState = .init(displayed: nil, interacted: nil)
            }
            expect(manager.getFilteredMessage(message: inline)).toEventually(beTrue(), timeout: .seconds(3))
            DispatchQueue.global().asyncAfter(deadline: .now() + 3.1) {
                inline.displayState = .init(displayed: nil, interacted: nil)
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 3.5) {
                inline.displayState = .init(displayed: Date(), interacted: Date())
            }
            expect(manager.getFilteredMessage(message: inline)).toEventually(beFalse(), timeout: .seconds(4))
        }

        it("prefetch") {
            let inlines = [
                SampleInlineMessage.getSampleIninlineMessage(placeholders: ["ph1"], personalized: .getSample(status: .ok, ttlSeen: Date())),
                SampleInlineMessage.getSampleIninlineMessage(placeholders: ["ph1"], personalized: .getSample(status: .ok, ttlSeen: Date())),
                SampleInlineMessage.getSampleIninlineMessage(placeholders: ["ph1"], personalized: .getSample(status: .ok, ttlSeen: Date())),
                SampleInlineMessage.getSampleIninlineMessage(placeholders: ["ph2"], personalized: .getSample(status: .ok, ttlSeen: Date())),
            ]
            expect(manager.prefetchPlaceholdersWithIds(input: inlines, ids: ["ph1"]).count).to(be(3))
            expect(manager.prefetchPlaceholdersWithIds(input: inlines, ids: ["ph2"]).count).to(be(1))
            expect(manager.prefetchPlaceholdersWithIds(input: inlines, ids: ["ph1", "ph2"]).count).to(be(4))
            expect(manager.prefetchPlaceholdersWithIds(input: inlines, ids: [""]).count).to(be(0))
        }

        it("queue") {
            var inline = SampleInlineMessage.getSampleIninlineMessage(frequency: .onlyOnce, personalized: .getSample(status: .ok, ttlSeen: Date()))
            var completionValue: Int = 0
            waitUntil(timeout: .seconds(25)) { done in
                for i in 0..<11 {
                    manager.refreshStaticViewContent(staticQueueData: .init(tag: inline.tags?.first ?? 0, placeholderId: inline.name, completion: { _ in
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
