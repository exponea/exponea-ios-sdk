//
//  ExponeaInternal+Jwt.swift
//  ExponeaSDK
//
//  Created by Bloomreach on 29/01/2026.
//  Copyright © 2026 Exponea. All rights reserved.
//

import Foundation

// MARK: - Stream JWT API

extension ExponeaInternal {
    
    /// Sets the Stream JWT token for Data Hub authentication.
    /// This token is used for all Stream API requests including tracking and App Inbox.
    /// Only effective when SDK is configured with Stream integration.
    /// JWT is cleared internally on anonymize, identifyCustomer without token, or clearLocalCustomerData.
    ///
    /// - Parameter token: The JWT token string (must be non-empty).
    public func setSdkAuthToken(_ token: String) {
        executeSafely { [weak self] in
            guard let self = self else { return }
            guard !token.isEmpty else {
                Exponea.logger.log(.warning, message: "Ignoring empty JWT token.")
                return
            }
            guard let jwtManager = self.jwtAuthManager else {
                Exponea.logger.log(.warning, message: "Cannot set JWT token before SDK is configured.")
                return
            }
            
            guard case .some(.stream) = self.configuration?.integrationConfig.type else {
                Exponea.logger.log(.warning, message: "Ignoring JWT token: SDK not configured with Stream integration.")
                return
            }
            jwtManager.setToken(token)
            Exponea.logger.log(.verbose, message: "Stream JWT token updated.")
        }
    }
    
    /// Sets a handler that will be called when JWT-related errors occur.
    /// Use this to refresh the JWT token when it expires or becomes invalid.
    ///
    /// - Parameter handler: Closure called with JWT error context when errors occur.
    public func setJwtErrorHandler(_ handler: @escaping (JwtErrorContext) -> Void) {
        executeSafely { [weak self] in
            guard let self = self else { return }
            guard let jwtManager = self.jwtAuthManager else {
                Exponea.logger.log(.warning, message: "Cannot set JWT error handler before SDK is configured.")
                return
            }
            
            jwtManager.setErrorHandler(handler)
            Exponea.logger.log(.verbose, message: "JWT error handler registered.")
        }
    }
}
