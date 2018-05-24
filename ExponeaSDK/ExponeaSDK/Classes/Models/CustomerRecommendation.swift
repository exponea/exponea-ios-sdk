//
//  CustomerRecommendation.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 11/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// <#Description#>
public struct CustomerRecommendation {
    
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
    public var items: [String: JSONConvertible]?
}
