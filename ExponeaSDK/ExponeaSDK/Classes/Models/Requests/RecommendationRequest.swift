//
//  CustomerRecommendation.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 11/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// Data type used to receive the customer recommendation parameters
/// to fetch the recommended items for a customer.
public struct RecommendationRequest {
    
    /// Type of recommendation to be retrieve.
    public var type: String
    
    /// Recommendation identification.
    public var id: String
    
    /// Number of items to fetch
    public var size: Int?
    
    /// Recommendation strategy. Eg.: `winner`, `mix`, `priority`.
    public var strategy: String?
    
    /// Indicates if should include items that customer has interacted with in the past.
    public var knowItems: Bool?
    
    /// Indicates if the we should return items most surprising to the customer
    public var anti: Bool?
    
    /// If present the recommendations are related not only to a customer,
    /// but to products with IDs specified in this hash.
    public var items: [String: JSONValue]?
    
    /// Recommendation initializer.
    ///
    /// - Parameters:
    ///   - type: Type of recommendation to be retrieve.
    ///   - id: Recommendation identification.
    ///   - size: Number of items to fetch.
    ///   - strategy: Recommendation strategy. Eg.: `winner`, `mix`, `priority`.
    ///   - knowItems: Indicates if should include items that customer has interacted with in the past.
    ///   - anti: Indicates if the we should return items most surprising to the customer.
    ///   - items: When recommendations are related not only to a customer,
    ///            but to products with IDs specified in this hash.
    public init(type: String,
                id: String,
                size: Int? = nil,
                strategy: String? = nil,
                knowItems: Bool? = nil,
                anti: Bool? = nil,
                items: [String: JSONValue]? = nil) {
        self.type = type
        self.id = id
        self.size = size
        self.strategy = strategy
        self.knowItems = knowItems
        self.anti = anti
        self.items = items
    }
}
