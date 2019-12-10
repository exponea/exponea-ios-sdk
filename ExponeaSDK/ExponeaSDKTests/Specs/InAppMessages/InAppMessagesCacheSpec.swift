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
}
