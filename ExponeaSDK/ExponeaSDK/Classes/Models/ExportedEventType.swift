//
//  ExportedEventType.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 20/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// <#Description#>
public struct ExportedEventType: Codable {
    public let type: String?
    public let timestamp: Double?
    public let properties: [String: String]?
    public let errors: [String: String]?
}
