//
//  MockJwtTokenStore.swift
//  ExponeaSDKTests
//
//  Created by Bloomreach on 03/02/2026.
//  Copyright © 2026 Exponea. All rights reserved.
//

import Foundation
@testable import ExponeaSDK
@testable import ExponeaSDKShared

/// Mock implementation of JwtTokenStore for testing.
final class MockJwtTokenStore: JwtTokenStore {

    /// Stored token (single token, no configId).
    private(set) var token: String?

    /// Tracks the number of times each method was called
    private(set) var loadCallCount = 0
    private(set) var saveCallCount = 0
    private(set) var clearCallCount = 0

    /// Last token passed to saveToken (including nil when clearing)
    private(set) var lastSavedToken: String?

    func loadToken() -> String? {
        loadCallCount += 1
        return token
    }

    func saveToken(_ token: String?) {
        saveCallCount += 1
        lastSavedToken = token
        self.token = token
    }

    func clearToken() {
        clearCallCount += 1
        token = nil
    }

    /// Resets all tracking counters and stored token
    func reset() {
        token = nil
        loadCallCount = 0
        saveCallCount = 0
        clearCallCount = 0
        lastSavedToken = nil
    }

    /// Pre-populate with a token for testing
    func setToken(_ token: String) {
        self.token = token
    }
}
