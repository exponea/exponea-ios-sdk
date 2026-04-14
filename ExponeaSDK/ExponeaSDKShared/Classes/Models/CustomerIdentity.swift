//
//  CustomerIdentity.swift
//  ExponeaSDK
//
//  Created by Bloomreach on 29/01/2026.
//  Copyright © 2026 Exponea. All rights reserved.
//

import Foundation

/// Type alias for customer identifiers dictionary (e.g., registered, external_id).
public typealias CustomerIds = [String: String]

/// Context containing customer identification and optional Stream JWT for SDK authentication.
/// Used when configuring or identifying customers in Stream integration mode.
public struct CustomerIdentity {
    /// Customer identifiers (e.g., registered email, external ID).
    public var customerIds: CustomerIds

    /// Optional Stream JWT token for authentication with Data Hub/Stream endpoints.
    /// Required for Stream integration mode, ignored in Engagement/Project mode.
    public var jwtToken: String?

    /// Creates a new customer identity context.
    /// - Parameters:
    ///   - customerIds: Customer identifiers dictionary.
    ///   - jwtToken: Optional Stream JWT token for Stream integration mode.
    public init(customerIds: CustomerIds, jwtToken: String? = nil) {
        self.customerIds = customerIds
        self.jwtToken = jwtToken
    }

    /// Creates an identity context with only a JWT token (no customer IDs).
    /// Use this when you only need to update the JWT token without changing customer identity.
    /// - Parameter jwtToken: The Stream JWT token.
    public init(jwtToken: String) {
        self.customerIds = [:]
        self.jwtToken = jwtToken
    }

    /// Creates an empty customer identity context.
    /// Useful as a starting point when building context incrementally.
    public init() {
        self.customerIds = [:]
        self.jwtToken = nil
    }

    /// Returns true if this context has any customer identification.
    public var hasCustomerIds: Bool {
        !customerIds.isEmpty
    }

    /// Returns true if this context has a JWT token.
    public var hasJwtToken: Bool {
        jwtToken != nil && !jwtToken!.isEmpty
    }
}

// MARK: - Codable

extension CustomerIdentity: Codable {}

// MARK: - Equatable

extension CustomerIdentity: Equatable {}
