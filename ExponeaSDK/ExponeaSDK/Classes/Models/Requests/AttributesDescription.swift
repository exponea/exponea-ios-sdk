//
//  CustomerAttributes.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 11/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//
    
import Foundation

/// <#Description#>
public struct AttributesDescription: Codable {
    
    /// <#Description#>
    public var typeKey: String
    
    /// <#Description#>
    public var typeValue: String
    
    /// <#Description#>
    public var identificationKey: String
    
    /// <#Description#>
    public var identificationValue: String
    
    public init(key: String, value: String, identificationKey: String, identificationValue: String) {
        self.typeKey = key
        self.typeValue = value
        self.identificationKey = identificationKey
        self.identificationValue = identificationValue
    }
}
