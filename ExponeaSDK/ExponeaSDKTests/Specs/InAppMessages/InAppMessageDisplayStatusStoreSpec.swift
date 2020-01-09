//
//  InAppMessageDisplayStatusStoreSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 18/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//
import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class InAppMessageDisplayStatusStoreSpec: QuickSpec {
    let message = SampleInAppMessage.getSampleInAppMessage()
    let emptyState = InAppMessageDisplayStatus(displayed: nil, interacted: nil)
    override func spec() {
        var userDefaults: UserDefaults!
        var displayStore: InAppMessageDisplayStatusStore!

        beforeEach {
            userDefaults = MockUserDefaults()
            displayStore = InAppMessageDisplayStatusStore(userDefaults: userDefaults)
        }

        it("should return empty data") {
            expect(displayStore.status(for: self.message)).to(equal(self.emptyState))
        }

        it("should save state") {
            let displayDate = Date(timeIntervalSince1970: 100)
            let intereractedDate = Date(timeIntervalSince1970: 200)
            let secondDisplayDate = Date(timeIntervalSince1970: 300)
            displayStore.didDisplay(self.message, at: displayDate)
            expect(displayStore.status(for: self.message))
                .to(equal(InAppMessageDisplayStatus(displayed: displayDate, interacted: nil)))
            displayStore.didInteract(with: self.message, at: intereractedDate)
            expect(displayStore.status(for: self.message))
                .to(equal(InAppMessageDisplayStatus(displayed: displayDate, interacted: intereractedDate)))
            displayStore.didDisplay(self.message, at: secondDisplayDate)
            expect(displayStore.status(for: self.message))
                .to(equal(InAppMessageDisplayStatus(displayed: secondDisplayDate, interacted: intereractedDate)))
        }

        it("should keep data between instances") {
            let displayDate = Date()
            displayStore.didDisplay(self.message, at: displayDate)
            expect(InAppMessageDisplayStatusStore(userDefaults: userDefaults).status(for: self.message))
                .to(equal(InAppMessageDisplayStatus(displayed: displayDate, interacted: nil)))
        }

        it("should delete old data") {
            let displayDate = Date(timeIntervalSince1970: 100)
            displayStore.didDisplay(self.message, at: displayDate)
            expect(InAppMessageDisplayStatusStore(userDefaults: userDefaults).status(for: self.message))
                .to(equal(self.emptyState))
        }

        it("should clear data") {
            let store = InAppMessageDisplayStatusStore(userDefaults: userDefaults)
            displayStore.didDisplay(self.message, at: Date())
            store.clear()
            expect(store.status(for: self.message))
                .to(equal(InAppMessageDisplayStatus(displayed: nil, interacted: nil)))
        }
    }
}
