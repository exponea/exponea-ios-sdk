//
//  EntityValueResponse.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 02/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// <#Description#>
public struct EntityValueResponse: Codable {
    
    /// <#Description#>
    public let success: Bool
    
    /// <#Description#>
    public let value: Double
    
    /// <#Description#>
    public let entityName: String
}
