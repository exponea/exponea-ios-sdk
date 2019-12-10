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
    func saveInAppMessages(inAppMessages: [InAppMessage]) {
        self.messages = inAppMessages
    }

    func getInAppMessages() -> [InAppMessage] {
        return messages
    }
}
