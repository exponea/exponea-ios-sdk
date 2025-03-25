//
//  InAppLayoutConfig.swift
//  ExponeaSDK
//
//  Created by Ankmara on 18.03.2025.
//  Copyright © 2025 Exponea. All rights reserved.
//

import Foundation

public struct InAppLayoutConfig: Codable {
    public let backgroundColor: String?
    public let margin: [InAppButtonEdge]
    public let padding: [InAppButtonEdge]
    public let cornerRadius: CGFloat
    public let buttonsAlign: InAppButtonAlignmentType
    public let textPosition: InAppButtonMarginType
    public let messagePosition: MessagePosition

    init(
        backgroundColor: String?,
        margin: [InAppButtonEdge],
        padding: [InAppButtonEdge],
        cornerRadius: CGFloat,
        buttonsAlign: InAppButtonAlignmentType,
        textPosition: InAppButtonMarginType,
        messagePosition: MessagePosition
    ) {
        self.backgroundColor = backgroundColor
        self.margin = margin
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.buttonsAlign = buttonsAlign
        self.textPosition = textPosition
        self.messagePosition = messagePosition
    }
}
