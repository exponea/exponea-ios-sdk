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
    
    /// Type of your event.
    public let type: String?
    
    /// <#Description#>
    public let timestamp: Double?
    
    /// <#Description#>
    public let properties: [String: JSONValue]?
    
    /// <#Description#>
    public let errors: [String: JSONValue]?
}

extension Event: CustomStringConvertible {
    public var description: String {
        let mappedProperties = properties?.mapValues({ $0.rawValue })
        let mappedErrors = errors?.mapValues({ $0.rawValue })
        
        var description = """
        [Event]
        Type: "\(type ?? "N/A")"
        Date: \(Date(timeIntervalSince1970: timestamp ?? 0))
        Properties: \(mappedProperties ?? [:])
        """
        
        if let errors = mappedErrors {
            description += "\nErrors: \(errors)"
        }
        
        return description
    }
}
