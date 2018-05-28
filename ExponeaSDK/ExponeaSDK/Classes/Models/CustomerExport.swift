//
//  CustomerExportModel.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 11/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// <#Description#>
public struct CustomerExport {
    
    /// <#Description#>
    public var attributes: CustomerAttributesGroup
    
    /// <#Description#>
    public var filter: [AnyHashable: JSONConvertible]
    
    /// <#Description#>
    public var executionTime: Int
    
    /// <#Description#>
    public var timezone: String
    
    /// <#Description#>
    public var responseFormat: String
}
