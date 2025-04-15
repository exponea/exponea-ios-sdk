//
//  InAppCloseButtonConfig.swift
//  ExponeaSDK
//
//  Created by Ankmara on 18.03.2025.
//  Copyright © 2025 Exponea. All rights reserved.
//

import SwiftUI
import UIKit
import Combine

public struct InAppCloseButtonConfig: Identifiable, Codable {
    public let id = UUID()
    public let margin: [InAppButtonEdge]
    public let size: CGSize = .init(width: 24, height: 24)
    public let imageURL: String?
    public let backgroundColor: String?
    public let iconColor: String?
    public let visibility: Bool
    @CodableIgnored
    public var dismissCallback: EmptyBlock?
    public var sizeWithPadding: CGSize {
        let width = size.width + 16
        let height = size.height + 16
        return .init(width: width, height: height)
    }

    public init(
        margin: [InAppButtonEdge],
        imageURL: String?,
        backgroundColor: String?,
        iconColor: String?,
        visibility: Bool
    ) {
        self.margin = margin
        self.imageURL = imageURL
        self.backgroundColor = backgroundColor
        self.iconColor = iconColor
        self.visibility = visibility
    }
}
