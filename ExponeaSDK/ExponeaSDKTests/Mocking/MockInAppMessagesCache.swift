//
//  MockInAppMessagesCache.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 05/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

@testable import ExponeaSDK

final class MockInAppMessagesCache: InAppMessagesCacheType {
    private var messages: [InAppMessage] = []
    private var images: [String: Data] = [:]

    func saveInAppMessages(inAppMessages: [InAppMessage]) {
        self.messages = inAppMessages
    }

    func getInAppMessages() -> [InAppMessage] {
        return messages
    }

    func deleteImages(except: [String]) {
        images = images.filter { except.contains($0.key) }
    }

    func hasImageData(at imageUrl: String) -> Bool {
        return images.contains { $0.key == imageUrl}
    }

    func saveImageData(at imageUrl: String, data: Data) {
        images[imageUrl] = data
    }

    func getImageData(at imageUrl: String) -> Data? {
        return images[imageUrl]
    }

    func clear() {
        images = [:]
        messages = []
    }
}
