//
//  InAppButtonConfig.swift
//  ExponeaSDK
//
//  Created by Ankmara on 29.10.2024.
//  Copyright © 2024 Exponea. All rights reserved.
//

import UIKit
import SwiftUI

public struct InAppButtonConfig: Identifiable, Codable {

    public var id = UUID()
    public let title: String
    public let backgroundColor: String?
    public let layout: InAppButtonLayoutType
    public let margin: [InAppButtonEdge]
    public let padding: [InAppButtonEdge]
    public let cornerRadius: CGFloat
    public let borderWeight: CGFloat
    public let borderColor: String?
    public let size: Int
    public let style: String
    public let lineHeight: CGFloat?
    public let textColor: String?
    public let fontURL: URL?
    public let textAlignment: InAppButtonAlignmentType?
    public let isEnabled: Bool
    public let isBorderEnabled: Bool
    public let type: InAppContentBlockActionType
    public let link: URL?
    @CodableIgnored
    public var actionCallback: TypeBlock<InAppMessagePayloadButton?>?
    @CodableIgnored
    public var payloadButton: InAppMessagePayloadButton?
    @CodableIgnored
    public var fontData: InAppButtonFontData?
    @CodableIgnored
    public var isWiderThanScreen = false
    public var calculatedLineHeight: CGFloat {
        var lineHeightToUse: CGFloat = 0
        if let lineHeight = lineHeight {
            let size = CGFloat(size)
            let lineHeight = lineHeight - size
            lineHeightToUse = lineHeight < 0 ? 0 : lineHeight
        }
        return lineHeightToUse
    }

    init(
        title: String,
        backgroundColor: String?,
        layout: InAppButtonLayoutType,
        margin: [InAppButtonEdge],
        padding: [InAppButtonEdge],
        cornerRadius: CGFloat,
        borderWeight: CGFloat,
        borderColor: String?,
        size: Int,
        style: String,
        lineHeight: CGFloat?,
        textColor: String?,
        fontURL: URL?,
        textAlignment: InAppButtonAlignmentType?,
        isEnabled: Bool,
        isBorderEnabled: Bool,
        type: InAppContentBlockActionType,
        link: URL?
    ) {
        self.title = title
        self.backgroundColor = backgroundColor
        self.layout = layout
        self.margin = margin
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.borderWeight = borderWeight
        self.borderColor = borderColor
        self.size = size
        self.style = style
        self.lineHeight = lineHeight
        self.textColor = textColor
        self.fontURL = fontURL
        self.textAlignment = textAlignment
        self.isEnabled = isEnabled
        self.isBorderEnabled = isBorderEnabled
        self.type = type
        self.link = link

        payloadButton = .init(
            buttonText: title,
            rawButtonType: type.rawValue,
            buttonLink: link?.absoluteString,
            buttonTextColor: textColor,
            buttonBackgroundColor: backgroundColor
        )
    }
}
