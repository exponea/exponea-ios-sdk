//
//  InAppButtonAlignmentType.swift
//  ExponeaSDK
//
//  Created by Ankmara on 18.03.2025.
//  Copyright © 2025 Exponea. All rights reserved.
//

import Foundation
import SwiftUI

public enum InAppButtonAlignmentType: String, Codable {
    case left
    case center
    case right

    public var alignment: HorizontalAlignment {
        switch self {
        case .center:
            return .center
        case .left:
            return .leading
        case .right:
            return .trailing
        }
    }

    public var textAlignment: SwiftUI.TextAlignment {
        switch self {
        case .center:
            return .center
        case .left:
            return .leading
        case .right:
            return .trailing
        }
    }

    public init(input: String?) {
        switch input?.lowercased() {
        case "left":
            self = .left
        case "right":
            self = .right
        default:
            self = .center
        }
    }
}
