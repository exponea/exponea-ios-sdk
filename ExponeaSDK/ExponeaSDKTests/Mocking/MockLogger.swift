//
//  MockLogger.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 04/09/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

@testable import ExponeaSDK

class MockLogger : Logger {
    public static var messages: [String] = []
    override open func logMessage(_ message: String) {
        MockLogger.messages.append(message)
        super.logMessage(message)
    }
}
