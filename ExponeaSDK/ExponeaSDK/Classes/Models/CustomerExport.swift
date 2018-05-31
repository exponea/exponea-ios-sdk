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
    public var attributes: AttributesListDescription?
    
    /// <#Description#>
    public var filter: [String: JSONValue]?
    
    /// <#Description#>
    public var executionTime: Int?
    
    /// <#Description#>
    public var timezone: String?
    
    /// <#Description#>
    public var responseFormat: ExportFormat
    
    /// <#Description#>
    ///
    /// - Parameters:
    ///   - attributes: <#attributes description#>
    ///   - filter: <#filter description#>
    ///   - executionTime: <#executionTime description#>
    ///   - timezone: <#timezone description#>
    ///   - responseFormat: <#responseFormat description#>
    public init(attributes: AttributesListDescription? = nil,
                filter: [String: JSONValue]? = nil,
                executionTime: Int? = nil,
                timezone: String? = nil,
                responseFormat: ExportFormat) {
        self.attributes = attributes
        self.filter = filter
        self.executionTime = executionTime
        self.timezone = timezone
        self.responseFormat = responseFormat
    }
}
