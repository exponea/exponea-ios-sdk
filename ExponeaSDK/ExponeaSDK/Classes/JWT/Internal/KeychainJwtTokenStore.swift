//
//  KeychainJwtTokenStore.swift
//  ExponeaSDKShared
//
//  Created by Bloomreach on 29/01/2026.
//  Copyright © 2026 Exponea. All rights reserved.
//

import Foundation
import Security

/// Keychain-based implementation of JwtTokenStore for secure JWT persistence.
final class KeychainJwtTokenStore: JwtTokenStore {
    
    private let service: String
    private let account: String
    
    /// Creates a new Keychain JWT token store.
    /// - Parameters:
    ///   - service: The keychain service identifier.
    ///   - accountPrefix: The keychain account identifier.
    init(
        service: String = "com.exponea.sdk.jwt",
        account: String = "streamJwt"
    ) {
        self.service = service
        self.account = account
    }
    
    func loadToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        switch status {
        case errSecSuccess:
            guard let data = item as? Data,
                  let token = String(data: data, encoding: .utf8) else {
                Exponea.logger.log(.warning, message: "JWT Keychain: Failed to decode token data for account \(account)")
                return nil
            }
            Exponea.logger.log(.verbose, message: "JWT Keychain: Successfully loaded token for account \(account)")
            return token
            
        case errSecItemNotFound:
            // This is expected when no token has been stored yet
            Exponea.logger.log(.verbose, message: "JWT Keychain: No token found for account \(account)")
            return nil
            
        default:
            Exponea.logger.log(.warning, message: "JWT Keychain: Failed to load token - OSStatus: \(status)")
            return nil
        }
    }
    
    func saveToken(_ token: String?) {
        guard let token = token else {
            clearToken()
            return
        }
        
        guard let data = token.data(using: .utf8) else {
            Exponea.logger.log(.error, message: "JWT Keychain: Failed to encode token to data")
            return
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        // Try to update existing item first
        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        switch updateStatus {
        case errSecSuccess:
            Exponea.logger.log(.verbose, message: "JWT Keychain: Token updated for account \(account)")
            
        case errSecItemNotFound:
            // Item doesn't exist, add it
            var addQuery = query
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            if addStatus == errSecSuccess {
                Exponea.logger.log(.verbose, message: "JWT Keychain: Token saved for account \(account)")
            } else {
                Exponea.logger.log(.error, message: "JWT Keychain: Failed to save token - OSStatus: \(addStatus)")
            }
            
        default:
            Exponea.logger.log(.error, message: "JWT Keychain: Failed to update token - OSStatus: \(updateStatus)")
        }
    }
    
    func clearToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        switch status {
        case errSecSuccess:
            Exponea.logger.log(.verbose, message: "JWT Keychain: Token cleared for account \(account)")
            
        case errSecItemNotFound:
            // Already cleared or never existed
            Exponea.logger.log(.verbose, message: "JWT Keychain: No token to clear for account \(account)")
            
        default:
            Exponea.logger.log(.warning, message: "JWT Keychain: Failed to clear token - OSStatus: \(status)")
        }
    }
}
