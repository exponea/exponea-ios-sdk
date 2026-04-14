//
//  ExampleAuthProvider.swift
//  Example
//
//  Created by Adam Mihalik on 31/01/2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation
import ExponeaSDK

@objc(ExponeaAuthProvider)
public class ExampleAuthProvider: NSObject, AuthorizationProviderType {
    required public override init() { }
    public func getAuthorizationToken() -> String? {
        // Receive and return JWT token here.
        return CustomerTokenStorage.shared.retrieveJwtToken()
        // NULL as returned value will be handled by SDK as 'no value'
    }
    
    public func getAuthorizationHeader() -> String? {
        return nil
    }
}
