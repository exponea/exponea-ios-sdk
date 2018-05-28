//
//  CustomerExportAttributesModel.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 11/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// <#Description#>
public struct CustomerAttributesGroup: Decodable {
    
    /// <#Description#>
    public var type: String
    
    /// <#Description#>
    public var list: [CustomerAttribute]
}
