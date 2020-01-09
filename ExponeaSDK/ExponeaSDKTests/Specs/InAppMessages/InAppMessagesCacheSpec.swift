//
//  InAppMessagesCacheSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 05/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//
import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class InAppMessagesCacheSpec: QuickSpec {
    override func spec() {
        beforeEach {
            let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            try? FileManager.default.removeItem(
                at: documentsDir!.appendingPathComponent(InAppMessagesCache.inAppMessagesFolder, isDirectory: true)
            )
        }
        describe("in-app message definition") {
            it("should get empty in-app messages on cold start") {
                expect(InAppMessagesCache().getInAppMessages()).to(beEmpty())
            }

            it("should save empty in-app messages") {
                let cache = InAppMessagesCache()
                cache.saveInAppMessages(inAppMessages: [])
                expect(cache.getInAppMessages()).to(beEmpty())
            }

            it("should save in-app messages") {
                let cache = InAppMessagesCache()
                let messages = [
                    SampleInAppMessage.getSampleInAppMessage(id: "first-mock-id"),
                    SampleInAppMessage.getSampleInAppMessage(id: "second-mock-id"),
                    SampleInAppMessage.getSampleInAppMessage(id: "third-mock-id")
                ]
                cache.saveInAppMessages(inAppMessages: messages)
                expect(cache.getInAppMessages()).to(equal(messages))
            }

            it("should keep in-app messages between instances") {
                InAppMessagesCache().saveInAppMessages(inAppMessages: [SampleInAppMessage.getSampleInAppMessage()])
                expect(InAppMessagesCache().getInAppMessages()).to(equal([SampleInAppMessage.getSampleInAppMessage()]))
            }
        }

        describe("in-app message images") {
            it("should get nil image for non-cached image") {
                let cache = InAppMessagesCache()
                expect(cache.getImageData(at: "http://domain.com/image.jpg")).to(beNil())
                expect(cache.hasImageData(at: "http://domain.com/image.jpg")).to(beFalse())
            }

            it("should save image") {
                let cache = InAppMessagesCache()
                cache.saveImageData(at: "http://domain.com/image.jpg", data: "data".data(using: .utf8)!)
                expect(cache.getImageData(at: "http://domain.com/image.jpg"))
                    .to(equal("data".data(using: .utf8)))
                expect(cache.hasImageData(at: "http://domain.com/image.jpg")).to(beTrue())
            }

            it("should delete images") {
                let cache = InAppMessagesCache()
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
            let cache = InAppMessagesCache()
            cache.saveInAppMessages(inAppMessages: [SampleInAppMessage.getSampleInAppMessage()])
            expect(cache.getInAppMessages()).to(equal([SampleInAppMessage.getSampleInAppMessage()]))
            cache.saveImageData(at: "http://domain.com/image1.jpg", data: "data1".data(using: .utf8)!)
            expect(cache.getImageData(at: "http://domain.com/image1.jpg")).notTo(beNil())
            cache.clear()
            expect(cache.getInAppMessages()).to(equal([]))
            expect(cache.getImageData(at: "http://domain.com/image1.jpg")).to(beNil())
        }
    }
}
