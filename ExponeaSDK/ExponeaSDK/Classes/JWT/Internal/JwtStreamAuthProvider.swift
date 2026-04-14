//
//  JwtStreamAuthProvider.swift
//  ExponeaSDK
//
//  Created by Bloomreach on 29/01/2026.
//  Copyright © 2026 Exponea. All rights reserved.
//

import Foundation

/// Internal auth provider that bridges JwtAuthManager with AuthorizationProviderType.
/// Used internally when SDK is configured with Stream integration to provide JWT tokens.
final class JwtStreamAuthProvider: NSObject, AuthorizationProviderType {
    
    private static let sharedLock = NSLock()
    private static var _shared: JwtStreamAuthProvider?

    /// Shared instance used when SDK is in Stream mode.
    /// Set by ExponeaInternal during initialization.
    /// Thread-safe: all accesses are serialized through `sharedLock`.
    static var shared: JwtStreamAuthProvider? {
        get {
            sharedLock.lock()
            defer { sharedLock.unlock() }
            return _shared
        }
        set {
            sharedLock.lock()
            defer { sharedLock.unlock() }
            _shared = newValue
        }
    }
    
    private weak var jwtAuthManager: JwtAuthManager?
    
    /// Required initializer - creates an instance that will use the shared JwtAuthManager.
    required override init() {
        super.init()
    }
    
    /// Creates a provider with a specific JwtAuthManager.
    /// - Parameter jwtAuthManager: The JWT auth manager to use.
    init(jwtAuthManager: JwtAuthManager) {
        self.jwtAuthManager = jwtAuthManager
        super.init()
    }
    
    func getAuthorizationToken() -> String? {
        manager?.currentTokenSnapshot
    }
    
    func getAuthorizationHeader() -> String? {
        manager?.getAuthorizationHeader()
    }
}

private extension JwtStreamAuthProvider {
    var manager: JwtAuthManager? {
        // Try instance-level manager first, fall back to shared
        if let manager = jwtAuthManager {
            return manager
        } else if let shared = JwtStreamAuthProvider.shared {
            return shared.jwtAuthManager
        }
        return nil
    }
}
