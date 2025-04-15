//
//  InAppButtonEdge.swift
//  ExponeaSDK
//
//  Created by Ankmara on 18.03.2025.
//  Copyright © 2025 Exponea. All rights reserved.
//

import Foundation

public struct InAppButtonEdge: Hashable, Identifiable, Codable {
    public var id = UUID()
    public let edge: InAppButtonMarginType
    public let value: CGFloat

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public init(edge: InAppButtonMarginType, value: CGFloat) {
        self.edge = edge
        self.value = value
    }
}
