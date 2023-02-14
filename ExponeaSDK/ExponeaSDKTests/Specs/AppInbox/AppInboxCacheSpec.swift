//
//  AppInboxCacheSpec.swift
//  ExponeaSDKTests
//
//  Created by Adam Mihalik on 08/11/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class AppInboxCacheSpec: QuickSpec {

    static func getSampleMessage(
        id: String,
        read: Bool = true,
        received: Double = Date().timeIntervalSince1970,
        type: String = "push",
        data: [String: JSONValue] = [:]
    ) -> MessageItem {
        return MessageItem(
            id: id,
            type: type,
            read: read,
            rawReceivedTime: received,
            rawContent: [
                "attributes": .dictionary([
                    "sent_timestamp": .double(received)
                ]),
                "silent": .bool(false),
                "has_tracking_consent": .bool(true)
            ].merging(data) { (_, new) in new }
        )
    }

    override func spec() {
        beforeEach {
            let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            try? FileManager.default.removeItem(
                at: documentsDir!.appendingPathComponent(AppInboxCache.appInboxFolder, isDirectory: true)
            )
            AppInboxCache().clear()
        }
        describe("AppInbox message definition") {
            it("should get empty AppInbox messages on cold start") {
                expect(AppInboxCache().getMessages()).to(beEmpty())
            }

            it("should save empty AppInbox messages") {
                let cache = AppInboxCache()
                cache.setMessages(messages: [])
                expect(cache.getMessages()).to(beEmpty())
            }

            it("should save AppInbox messages") {
                let cache = AppInboxCache()
                let messages = [
                    AppInboxCacheSpec.getSampleMessage(id: "first-mock-id"),
                    AppInboxCacheSpec.getSampleMessage(id: "second-mock-id"),
                    AppInboxCacheSpec.getSampleMessage(id: "third-mock-id")
                ]
                cache.setMessages(messages: messages)
                expect(cache.getMessages()).to(contain(messages))
            }

            it("should update AppInbox message") {
                let cache = AppInboxCache()
                let msg1 = AppInboxCacheSpec.getSampleMessage(id: "id1", read: false)
                let msg2 = AppInboxCacheSpec.getSampleMessage(id: "id1", read: true)
                cache.setMessages(messages: [msg1])
                cache.addMessages(messages: [msg2])
                expect(cache.getMessages().count).to(equal(1))
                expect(cache.getMessages()[0].read).to(equal(true))
            }

            it("should keep AppInbox messages between instances") {
                var firstMessage = AppInboxCacheSpec.getSampleMessage(id: "first-mock-id")
                firstMessage.customerId = "some"
                firstMessage.syncToken = "some"
                AppInboxCache().setMessages(messages: [firstMessage])
                var secondMessage = AppInboxCacheSpec.getSampleMessage(id: "first-mock-id")
                secondMessage.customerId = "some"
                secondMessage.syncToken = "some"
                expect(AppInboxCache().getMessages()).to(equal([secondMessage]))
            }
            
            it("should save messages automatically latest first") {
                let cache = AppInboxCache()
                let now = Date().timeIntervalSince1970.doubleValue
                let unsortedMessages = [
                    AppInboxCacheSpec.getSampleMessage(id: "id1", received: now - 20),
                    AppInboxCacheSpec.getSampleMessage(id: "id2", received: now - 10),
                    AppInboxCacheSpec.getSampleMessage(id: "id3", received: now - 3)
                ]
                cache.setMessages(messages: unsortedMessages)
                let sortedMessages = cache.getMessages()
                expect(sortedMessages.count).to(equal(3))
                expect(sortedMessages[0].id).to(equal("id3"))
                expect(sortedMessages[1].id).to(equal("id2"))
                expect(sortedMessages[2].id).to(equal("id1"))
            }

            it("should save messages automatically latest first after add") {
                let cache = AppInboxCache()
                let now = Date().timeIntervalSince1970.doubleValue;
                let unsortedMessages = [
                    AppInboxCacheSpec.getSampleMessage(id: "id1", received: now - 20),
                    AppInboxCacheSpec.getSampleMessage(id: "id2", received: now - 10)
                ]
                cache.setMessages(messages: unsortedMessages)
                let sortedMessages = cache.getMessages()
                expect(sortedMessages.count).to(equal(2))
                expect(sortedMessages[0].id).to(equal("id2"))
                expect(sortedMessages[1].id).to(equal("id1"))
                cache.addMessages(messages: [AppInboxCacheSpec.getSampleMessage(id: "id3", received: now - 3)])
                let afterUpdateMessages = cache.getMessages()
                expect(afterUpdateMessages.count).to(equal(3))
                expect(afterUpdateMessages[0].id).to(equal("id3"))
                expect(afterUpdateMessages[1].id).to(equal("id2"))
                expect(afterUpdateMessages[2].id).to(equal("id1"))
            }

            it("should save messages automatically latest first after update") {
                let cache = AppInboxCache()
                let now = Date().timeIntervalSince1970.doubleValue;
                let unsortedMessages = [
                    AppInboxCacheSpec.getSampleMessage(id: "id1", received: now - 20),
                    AppInboxCacheSpec.getSampleMessage(id: "id2", received: now - 10),
                    AppInboxCacheSpec.getSampleMessage(id: "id3", received: now - 3)
                ]
                cache.setMessages(messages: unsortedMessages)
                let sortedMessages = cache.getMessages()
                expect(sortedMessages.count).to(equal(3))
                expect(sortedMessages[0].id).to(equal("id3"))
                expect(sortedMessages[1].id).to(equal("id2"))
                expect(sortedMessages[2].id).to(equal("id1"))
                cache.addMessages(messages: [AppInboxCacheSpec.getSampleMessage(id: "id2", received: now - 1)])
                let afterUpdateMessages = cache.getMessages()
                expect(afterUpdateMessages.count).to(equal(3))
                expect(afterUpdateMessages[0].id).to(equal("id2"))
                expect(afterUpdateMessages[1].id).to(equal("id3"))
                expect(afterUpdateMessages[2].id).to(equal("id1"))
            }
        }

        describe("AppInbox message images") {
            it("should get nil image for non-cached image") {
                let cache = AppInboxCache()
                expect(cache.getImageData(at: "http://domain.com/image.jpg")).to(beNil())
                expect(cache.hasImageData(at: "http://domain.com/image.jpg")).to(beFalse())
            }

            it("should save image") {
                let cache = AppInboxCache()
                cache.saveImageData(at: "http://domain.com/image.jpg", data: "data".data(using: .utf8)!)
                expect(cache.getImageData(at: "http://domain.com/image.jpg"))
                    .to(equal("data".data(using: .utf8)))
                expect(cache.hasImageData(at: "http://domain.com/image.jpg")).to(beTrue())
            }

            it("should delete images") {
                let cache = AppInboxCache()
                cache.saveImageData(at: "http://domain.com/image1.jpg", data: "data1".data(using: .utf8)!)
                cache.saveImageData(at: "http://domain.com/image2.jpg", data: "data2".data(using: .utf8)!)
                cache.saveImageData(at: "http://domain.com/image3.jpg", data: "data3".data(using: .utf8)!)
                cache.saveImageData(at: "http://domain.com/image4.jpg", data: "data4".data(using: .utf8)!)
                cache.deleteImages(except: ["http://domain.com/image3.jpg"])
                expect(cache.getImageData(at: "http://domain.com/image1.jpg")).to(beNil())
                expect(cache.getImageData(at: "http://domain.com/image2.jpg")).to(beNil())
                expect(cache.getImageData(at: "http://domain.com/image3.jpg"))
                    .to(equal("data3".data(using: .utf8)))
                expect(cache.getImageData(at: "http://domain.com/image4.jpg")).to(beNil())
            }
        }

        it("should clear data") {
            let cache = AppInboxCache()
            cache.setMessages(messages: [AppInboxCacheSpec.getSampleMessage(id: "first-mock-id")])
            expect(cache.getMessages()).to(equal([AppInboxCacheSpec.getSampleMessage(id: "first-mock-id")]))
            cache.saveImageData(at: "http://domain.com/image1.jpg", data: "data1".data(using: .utf8)!)
            expect(cache.getImageData(at: "http://domain.com/image1.jpg")).notTo(beNil())
            cache.clear()
            expect(cache.getMessages()).to(equal([]))
            expect(cache.getImageData(at: "http://domain.com/image1.jpg")).to(beNil())
        }
    }
}
