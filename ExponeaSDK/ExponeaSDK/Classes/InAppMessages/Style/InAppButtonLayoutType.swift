//
//  InAppButtonLayoutType.swift
//  ExponeaSDK
//
//  Created by Ankmara on 18.03.2025.
//  Copyright © 2025 Exponea. All rights reserved.
//

import Foundation

public enum InAppButtonLayoutType: String, Codable {
    case hug
    case fill

    public init(input: String?) {
        switch input?.lowercased() {
        case "fill":
            self = .fill
        case "hug_text":
            self = .hug
        default:
            self = .fill
        }
    }
}
