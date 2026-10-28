//
//  InAppButtonFontData.swift
//  ExponeaSDK
//
//  Created by Ankmara on 18.03.2025.
//  Copyright © 2025 Exponea. All rights reserved.
//

import UIKit

public struct InAppButtonFontData: Codable {
    public var fontName: String?
    public var fontSize: CGFloat?
    public var fontData: String?
    @CodableIgnored
    public var loadedFont: UIFont? = .init()

    public init(fontName: String? = nil, fontSize: CGFloat? = nil, fontData: String? = nil) {
        self.fontName = fontName
        self.fontSize = fontSize
        self.fontData = fontData

        loadedFont = extractFont()
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.fontName = try container.decodeIfPresent(String.self, forKey: .fontName)
        self.fontSize = try container.decodeIfPresent(CGFloat.self, forKey: .fontSize)
        self.fontData = try container.decodeIfPresent(String.self, forKey: .fontData)

        loadedFont = extractFont()
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.fontName, forKey: .fontName)
        try container.encodeIfPresent(self.fontSize, forKey: .fontSize)
        try container.encodeIfPresent(self.fontData, forKey: .fontData)
    }

    enum CodingKeys: CodingKey {
        case fontName
        case fontSize
        case fontData
    }

    private mutating func extractFont() -> UIFont? {
        if let registeredFont = fontName,
           let size = fontSize,
           let font = UIFont(name: registeredFont, size: size) {
            return font
        }
        return InAppFontLoader.load(base64: fontData, size: fontSize)
    }
}
