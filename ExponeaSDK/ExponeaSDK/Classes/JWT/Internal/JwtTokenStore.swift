//
//  JwtTokenStore.swift
//  ExponeaSDKShared
//
//  Created by Bloomreach on 29/01/2026.
//  Copyright © 2026 Exponea. All rights reserved.
//

import Foundation

/// Protocol for persisting Stream JWT tokens.
/// Implementations handle secure storage and retrieval of JWT tokens.
protocol JwtTokenStore {
    /// Loads a stored JWT token.
    /// - Returns: The stored JWT token, or nil if not found.
    func loadToken() -> String?
    
    /// Saves or updates a JWT token.
    /// - Parameters:
    ///   - token: The JWT token to save, or nil to clear the token.
    func saveToken(_ token: String?)
    
    /// Clears the stored JWT token.
    func clearToken()
}
