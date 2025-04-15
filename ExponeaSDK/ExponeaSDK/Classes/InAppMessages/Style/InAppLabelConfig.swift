//
//  InAppLabelConfig.swift
//  ExponeaSDK
//
//  Created by Ankmara on 18.03.2025.
//  Copyright © 2025 Exponea. All rights reserved.
//

import UIKit

public struct InAppLabelConfig: InAppTextConfigurable, Codable {
    public var text: String?
    public var size: CGFloat
    public var style: String?
    public var alignment: String?
    public var color: String?
    public var lineHeight: CGFloat?
    public var customFont: String?
    public var isVisible: Bool
    public var padding: [InAppButtonEdge] = []
    public var fontData: InAppButtonFontData?

    public init(
        text: String?,
        size: CGFloat,
        style: String?,
        alignment: String? = nil,
        color: String? = nil,
        lineHeight: CGFloat? = nil,
        customFont: String? = nil,
        isVisible: Bool,
        padding: [InAppButtonEdge],
        fontData: InAppButtonFontData?
    ) {
        self.text = text
        self.size = size
        self.style = style
        self.alignment = alignment
        self.color = color
        self.lineHeight = lineHeight
        self.customFont = customFont
        self.isVisible = isVisible
        self.padding = padding
        self.fontData = fontData
    }
}

public struct InAppBodyLabelConfig: InAppTextConfigurable {
    public var text: String?
    public var size: CGFloat
    public var style: String?
    public var alignment: String?
    public var color: String?
    public var lineHeight: CGFloat?
    public var customFont: String?
    @CodableIgnored
    public var loadedCustomFont: UIFont?
    public var isVisible: Bool
    public var padding: [InAppButtonEdge] = []
    public var fontData: InAppButtonFontData?

    public init(
        text: String?,
        size: CGFloat,
        style: String?,
        alignment: String? = nil,
        color: String? = nil,
        lineHeight: CGFloat? = nil,
        customFont: String? = nil,
        isVisible: Bool,
        padding: [InAppButtonEdge],
        fontData: InAppButtonFontData?
    ) {
        self.text = text
        self.size = size
        self.style = style
        self.alignment = alignment
        self.color = color
        self.lineHeight = lineHeight
        self.customFont = customFont
        self.isVisible = isVisible
        self.padding = padding
        self.fontData = fontData
    }
}
