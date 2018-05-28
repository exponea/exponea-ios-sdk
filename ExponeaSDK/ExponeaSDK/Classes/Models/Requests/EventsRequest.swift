//
//  FetchEventsRequest.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 11/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// <#Description#>
public struct EventsRequest {
    
    /// <#Description#>
    public var eventTypes: [String]
    
    /// <#Description#>
    public var sortOrder: String = "desc"
    
    /// <#Description#>
    public var limit: Int = 3
    
    /// <#Description#>
    public var skip: Int = 100
    
    /// <#Description#>
    ///
    /// - Parameters:
    ///   - evenTypes: <#evenTypes description#>
    ///   - sortOrder: <#sortOrder description#>
    ///   - limit: <#limit description#>
    ///   - skip: <#skip description#>
    public init(eventTypes: [String],
                sortOrder: String = "desc",
                limit: Int = 3,
                skip: Int = 100) {
        self.eventTypes = eventTypes
        self.sortOrder = sortOrder
        self.limit = limit
        self.skip = skip
    }
}
