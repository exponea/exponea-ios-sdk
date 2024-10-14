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
import Combine
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
        
        it("message changed") {
            var wasMessageChanged = false
            let view = CarouselInAppContentBlockView(placeholder: "placeholder")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                view.state = .refresh
            }
            waitUntil(timeout: .seconds(2)) { done in
                view.onMessageChanged = { _ in
                    wasMessageChanged = true
                    done()
                }
            }
            expect(wasMessageChanged).to(beTrue())
        }
        
        it("overlimit") {
            let array: [Int] = [1, 2, 3, 4, 5]
            let maxOverLimit = 10
            let result = array.prefix(maxOverLimit)
            expect(result.count).to(be(5))
        }

        it("multipler") {
            let view = CarouselInAppContentBlockView(placeholder: "")
            let a = view.makeDuplicate(input: [.init(html: "a", tag: 1)])
            expect(a.count).to(be(1))
            let b = view.makeDuplicate(input: [.init(html: "a", tag: 1), .init(html: "a", tag: 2), .init(html: "b", tag: 3)])
            expect(b.count).to(be(150))
            expect(b.filter({ $0.html == "b" }).count).to(be(50))
            let c = view.makeDuplicate(input: [
                .init(html: "a", tag: 1),
                .init(html: "a", tag: 2),
                .init(html: "b", tag: 3),
                .init(html: "b", tag: 4),
                .init(html: "c", tag: 5),
                .init(html: "c", tag: 6)
            ])
            expect(c.count).to(be(150))
            expect(c.filter({ $0.tag == 6 }).count).to(be(25))
            let d = view.makeDuplicate(input: [
                .init(html: "a", tag: 1),
                .init(html: "a", tag: 2),
                .init(html: "b", tag: 3),
                .init(html: "b", tag: 4),
                .init(html: "c", tag: 5),
                .init(html: "c", tag: 6),
                .init(html: "d", tag: 7),
                .init(html: "d", tag: 8),
                .init(html: "e", tag: 9),
                .init(html: "e", tag: 10),
                .init(html: "f", tag: 11)
            ])
            expect(d.count).to(be(110))
            expect(d.filter({ $0.tag == 6 }).count).to(be(10))
            expect(d.filter({ $0.html == "c" }).count).to(be(20))
        }

        it("is valid check") {
            let messageExpired: StaticReturnData = .init(
                html: "",
                tag: 0,
                message: .init(
                    id: UUID().uuidString,
                    name: "",
                    dateFilter: .init(
                        enabled: false,
                        fromDate: nil,
                        toDate: nil
                    ),
                    frequency: .untilVisitorInteracts,
                    placeholders: [""],
                    tags: [],
                    loadPriority: 100,
                    content: nil,
                    personalized: .getSample(status: .ok, ttlSeen: Date().addingTimeInterval(-10000))
                )
            )
            
             var userDefaults: UserDefaults = {
                if UserDefaults(suiteName: Constants.General.userDefaultsSuite) == nil {
                    UserDefaults.standard.addSuite(named: Constants.General.userDefaultsSuite)
                }
                return UserDefaults(suiteName: Constants.General.userDefaultsSuite)!
            }()
            
            let store = InAppContentBlockDisplayStatusStore(userDefaults: userDefaults)

            var messageInvalidInteracted: StaticReturnData = .init(
                html: "",
                tag: 0,
                message: .init(
                    id: UUID().uuidString,
                    name: "",
                    dateFilter: .init(
                        enabled: false,
                        fromDate: nil,
                        toDate: nil
                    ),
                    frequency: .untilVisitorInteracts,
                    placeholders: [""],
                    tags: [],
                    loadPriority: 100,
                    content: nil,
                    personalized: .getSample(status: .ok, ttlSeen: Date())
                )
            )
            store.didInteract(with: messageInvalidInteracted.message?.id ?? "", at: Date().addingTimeInterval(4000))

            var messageInvalidShowed: StaticReturnData = .init(
                html: "",
                tag: 0,
                message: .init(
                    id: UUID().uuidString,
                    name: "",
                    dateFilter: .init(
                        enabled: false,
                        fromDate: nil,
                        toDate: nil
                    ),
                    frequency: .oncePerVisit,
                    placeholders: [""],
                    tags: [],
                    loadPriority: 100,
                    content: nil,
                    personalized: .getSample(status: .ok, ttlSeen: Date())
                )
            )
            store.didDisplay(of: messageInvalidShowed.message?.id ?? "", at: Date().addingTimeInterval(4000))

            var messageValid: StaticReturnData = .init(
                html: "",
                tag: 0,
                message: .init(
                    id: UUID().uuidString,
                    name: "",
                    dateFilter: .init(
                        enabled: false,
                        fromDate: nil,
                        toDate: nil
                    ),
                    frequency: .always,
                    placeholders: [""],
                    tags: [],
                    loadPriority: 100,
                    content: nil,
                    personalized: .getSample(status: .ok, ttlSeen: Date().addingTimeInterval(4000))
                )
            )

            var isMessageExpiredAndValid = false
            waitUntil(timeout: .seconds(2)) { done in
                manager.isMessageValid(message: messageExpired.message!) { _ in
                } refreshCallback: {
                    isMessageExpiredAndValid = true
                    done()
                }
            }
            expect(isMessageExpiredAndValid).to(beTrue())

            var isMessageInvalid = false
            waitUntil(timeout: .seconds(2)) { done in
                manager.isMessageValid(message: messageInvalidInteracted.message!) { isValid in
                    isMessageInvalid = !isValid
                    done()
                } refreshCallback: {
                }
            }
            expect(isMessageInvalid).to(beTrue())

            var isMessageInvalidShowed = false
            waitUntil(timeout: .seconds(2)) { done in
                manager.isMessageValid(message: messageInvalidShowed.message!) { isValid in
                    isMessageInvalidShowed = !isValid
                    done()
                } refreshCallback: {
                }
            }
            expect(isMessageInvalidShowed).to(beTrue())

            var isMessageValid = false
            waitUntil(timeout: .seconds(2)) { done in
                manager.isMessageValid(message: messageValid.message!) { isValid in
                    isMessageValid = isValid
                    done()
                } refreshCallback: {
                }
            }
            expect(isMessageValid).to(beTrue())
        }
    }
}
