//
//  CustomerRecommendation.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 11/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// <#Description#>
public struct RecommendationRequest {
    
    /// <#Description#>
    public var type: String
    
    /// <#Description#>
    public var id: String
    
    /// <#Description#>
    public var size: Int?
    
    /// <#Description#>
    public var strategy: String?
    
    /// <#Description#>
    public var knowItems: Bool?
    
    /// <#Description#>
    public var anti: Bool?
    
    /// <#Description#>
    public var items: [AnyHashable: JSONConvertible]?
    
    /// <#Description#>
    ///
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - id: <#id description#>
    ///   - size: <#size description#>
    ///   - strategy: <#strategy description#>
    ///   - knowItems: <#knowItems description#>
    ///   - anti: <#anti description#>
    ///   - items: <#items description#>
    public init(type: String,
                id: String,
                size: Int?,
                strategy: String?,
                knowItems: Bool?,
                anti: Bool?,
                items: [AnyHashable: JSONConvertible]?) {
        self.type = type
        self.id = id
        self.size = size
        self.strategy = strategy
        self.knowItems = knowItems
        self.anti = anti
        self.items = items
    }
}
