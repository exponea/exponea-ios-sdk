//
//  ExportedEventType.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 20/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// <#Description#>
public struct Event: Codable {
    
    /// <#Description#>
    public let type: String?
    
    /// <#Description#>
    public let timestamp: Double?
    
    /// <#Description#>
    public let properties: [String: String]?
    
    /// <#Description#>
    public let errors: [String: String]?
}
