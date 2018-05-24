//
//  CustomerExportModel.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 11/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// <#Description#>
public struct CustomerExportModel {
    
    /// <#Description#>
    public var attributes: CustomerExportAttributesModel
    
    /// <#Description#>
    public var filter: [String: JSONConvertible]
    
    /// <#Description#>
    public var executionTime: Int
    
    /// <#Description#>
    public var timezone: String
    
    /// <#Description#>
    public var responseFormat: String
}
