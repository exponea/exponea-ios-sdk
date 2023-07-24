//
//  InlineMessageContentType.swift
//  ExponeaSDK
//
//  Created by Ankmara on 29.05.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//
import Foundation

public enum InlineMessageContentType: String, Codable , Hashable {
    case html
    case native
    
    public init?(status: String) {
        guard let status = Self.init(rawValue: status) else {
            return nil
        }
        self = status
    }
}
