//
//  FetchEventsRequest.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 11/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// <#Description#>
public struct FetchEventsRequest {
    
    /// <#Description#>
    public var eventTypes: [String]
    
    /// <#Description#>
    public var sortOrder: String = "desc"
    
    /// <#Description#>
    public var limit: Int = 3
    
    /// <#Description#>
    public var skip: Int = 100
}
