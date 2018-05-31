//
//  ErrorResponse.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 31/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// <#Description#>
public struct ErrorResponse: Codable {
    
    /// <#Description#>
    var errors: ErrorContent
    
    /// <#Description#>
    var success: Bool
}

/// <#Description#>
public struct ErrorContent: Codable {
    
    /// <#Description#>
    var code: Int
    
    /// <#Description#>
    var description: String
    
    /// <#Description#>
    var message: String
}
