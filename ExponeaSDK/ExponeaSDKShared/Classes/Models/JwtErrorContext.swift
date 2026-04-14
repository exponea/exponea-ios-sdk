//
//  JwtErrorContext.swift
//  ExponeaSDK
//
//  Created by Bloomreach on 29/01/2026.
//  Copyright © 2026 Exponea. All rights reserved.
//

import Foundation

/// Context provided to JWT error handlers when the SDK needs a new auth token.
/// Aligns with Android `SdkAuthError`: error code plus optional customer IDs.
///
/// Endpoint path and HTTP status are intentionally not exposed in the public API;
/// they are used internally for debugging only.
public struct JwtErrorContext {

    /// Describes why the SDK is requesting a new auth token.
    /// Always include an `else` branch when switching on this enum
    /// to ensure forward compatibility with future SDK versions.
    public enum Reason {
        /// JWT token was not provided when required.
        case notProvided
        /// JWT token is invalid (malformed or signature verification failed).
        case invalid
        /// JWT token has expired.
        case expired
        /// JWT token is about to expire (proactive notification before sending request).
        case expiredSoon
        /// Reserved for future use. Not currently emitted by the SDK.
        /// Retained as a public case for API compatibility.
        case insufficient
    }

    /// The reason for this JWT error (equivalent to Android `SdkAuthErrorCode`).
    public let reason: Reason

    /// Current customer IDs when the error occurred, if available (e.g. for the integrator to request a new token for the same customer).
    /// May be nil when the error is proactive (e.g. expiredSoon) or before customer identification.
    public let customerIds: [String: String]?

    /// Creates a new JWT error context.
    /// - Parameters:
    ///   - reason: The reason for the JWT error.
    ///   - customerIds: Optional current customer IDs.
    public init(
        reason: Reason,
        customerIds: [String: String]? = nil
    ) {
        self.reason = reason
        self.customerIds = customerIds
    }
}
