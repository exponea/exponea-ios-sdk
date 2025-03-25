//
//  InAppMessagePayload.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 28/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

public struct InAppButtonPayload: Codable {
    public var id = UUID()
    public let buttonText: String
    public let buttonBackgroundColor: String?
    public let buttonLayout: String?
    public let buttonMargin: String?
    public let buttonPadding: String?
    public let buttonCornerRadius: String?
    public let buttonBorderWidth: String?
    public let buttonBorderColor: String?
    public let buttonFontSize: String?
    public let buttonStyle: [String]
    public let buttonLineHeight: String?
    public let buttonTextColor: String?
    public let buttonFontUrl: URL?
    public let buttonTextAlignment: String?
    public let buttonEnabled: Bool
    public let buttonType: String?
    public let buttonLink: URL?
    public let buttonHasBorder: Bool?
    public var buttonConfig: InAppButtonConfig?
    public var fontData: InAppButtonFontData?

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.buttonText = try container.decode(String.self, forKey: .buttonText)
        self.buttonBackgroundColor = try container.decodeIfPresent(String.self, forKey: .buttonBackgroundColor)
        self.buttonLayout = try container.decodeIfPresent(String.self, forKey: .buttonLayout)
        self.buttonMargin = try container.decodeIfPresent(String.self, forKey: .buttonMargin)
        self.buttonPadding = try container.decodeIfPresent(String.self, forKey: .buttonPadding)
        self.buttonCornerRadius = try container.decodeIfPresent(String.self, forKey: .buttonCornerRadius)
        self.buttonBorderWidth = try container.decodeIfPresent(String.self, forKey: .buttonBorderWidth)
        self.buttonBorderColor = try container.decodeIfPresent(String.self, forKey: .buttonBorderColor)
        self.buttonFontSize = try container.decodeIfPresent(String.self, forKey: .buttonFontSize)
        self.buttonStyle = try container.decodeIfPresent([String].self, forKey: .buttonStyle) ?? []
        self.buttonLineHeight = try container.decodeIfPresent(String.self, forKey: .buttonLineHeight)
        self.buttonTextColor = try container.decodeIfPresent(String.self, forKey: .buttonTextColor)
        self.buttonFontUrl = URL(string: try container.decodeIfPresent(String.self, forKey: .buttonFontUrl) ?? "")
        self.buttonTextAlignment = try container.decodeIfPresent(String.self, forKey: .buttonTextAlignment)
        self.buttonEnabled = try container.decodeIfPresent(Bool.self, forKey: .buttonEnabled) ?? false
        self.buttonType = try container.decodeIfPresent(String.self, forKey: .buttonType)
        self.buttonLink = URL(string: try container.decodeIfPresent(String.self, forKey: .buttonLink) ?? "")
        self.buttonHasBorder = try container.decodeIfPresent(Bool.self, forKey: .buttonHasBorder)
        var padding: [InAppButtonEdge] = []
        if let paddings = buttonPadding {
            padding = paddings.calculatePaddings()
        }
        var margin: [InAppButtonEdge] = []
        if let margins = buttonMargin {
            margin = margins.calculatePaddings()
        }

        if buttonEnabled {
            buttonConfig = .init(
                title: buttonText,
                backgroundColor: buttonBackgroundColor,
                layout: .init(input: buttonLayout),
                margin: margin,
                padding: padding,
                cornerRadius: buttonCornerRadius?.convertPxToFloatWithDefaultValue() ?? 0,
                borderWeight: buttonBorderWidth?.convertPxToFloatWithDefaultValue() ?? 0,
                borderColor: buttonBorderColor,
                size: Int(buttonFontSize?.convertPxToFloatWithDefaultValue() ?? 16),
                style: buttonStyle.joined(separator: "+").lowercased(),
                lineHeight: buttonLineHeight?.convertPxToFloatWithDefaultValue() ?? 0,
                textColor: buttonTextColor,
                fontURL: buttonFontUrl,
                textAlignment: .init(input: buttonTextAlignment),
                isEnabled: buttonEnabled,
                isBorderEnabled: buttonHasBorder ?? false,
                type: .init(input: buttonType),
                link: buttonLink
            )
        }

        let fontDataBuffer = try? container.decodeIfPresent(InAppButtonFontData.self, forKey: .fontData)
        var hm = fontDataBuffer
        if hm?.fontName != nil && buttonEnabled {
            if let font = extractFont(base64: fontDataBuffer?.fontData, size: fontDataBuffer?.fontSize) {
                hm?.loadedFont = font
            } else if let name = hm?.fontName, let size = buttonConfig?.size {
                hm?.loadedFont = UIFont(name: name, size: CGFloat(size))
            }
            self.buttonConfig?.fontData = hm
        } else if let url = buttonFontUrl {
            self.fontData = extractFont(url: url, fontSize: buttonFontSize, size: nil)
        }
    }

    
    func extractFont(url: URL, fontSize: String?, size: CGFloat?) -> InAppButtonFontData? {
        if let data = try? Data(contentsOf: url),
           let dataProvider = CGDataProvider(data: data as CFData),
           let cgFont = CGFont(dataProvider) {
            var fontData: InAppButtonFontData = .init()
            var error: Unmanaged<CFError>?
            if CTFontManagerRegisterGraphicsFont(cgFont, &error) {
                let size = size ?? fontSize?.convertPxToFloatWithDefaultValue() ?? 13
                fontData.fontName = cgFont.postScriptName as? String
                fontData.fontSize = size
                fontData.fontData = data.base64EncodedString()
                if let fontName = cgFont.postScriptName as? String {
                    fontData.loadedFont = UIFont(name: fontName, size: size)
                }
                CTFontManagerUnregisterGraphicsFont(cgFont, &error)
            }
            return fontData
        }
        return nil
    }
    
    private func extractFont(base64: String?, size: CGFloat?) -> UIFont? {
        if let base64 = base64,
           let data = Data(base64Encoded: base64),
           let dataProvider = CGDataProvider(data: data as CFData),
           let cgFont = CGFont(dataProvider) {
            var error: Unmanaged<CFError>?
            if CTFontManagerRegisterGraphicsFont(cgFont, &error) {
                var font: UIFont?
                if let fontName = cgFont.postScriptName as? String {
                    font = UIFont(name: fontName, size: size ?? 13)
                }
                CTFontManagerUnregisterGraphicsFont(cgFont, &error)
                return font
            }
        }
        return nil
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(buttonText, forKey: .buttonText)
        try container.encodeIfPresent(buttonBackgroundColor, forKey: .buttonBackgroundColor)
        try container.encodeIfPresent(buttonTextColor, forKey: .buttonTextColor)
        try container.encodeIfPresent(buttonLayout, forKey: .buttonLayout)
        try container.encodeIfPresent(buttonMargin, forKey: .buttonMargin)
        try container.encodeIfPresent(buttonPadding, forKey: .buttonPadding)
        try container.encodeIfPresent(buttonCornerRadius, forKey: .buttonCornerRadius)
        try container.encodeIfPresent(buttonBorderWidth, forKey: .buttonBorderWidth)
        try container.encodeIfPresent(buttonBorderColor, forKey: .buttonBorderColor)
        try container.encodeIfPresent(buttonFontSize, forKey: .buttonFontSize)
        try container.encodeIfPresent(buttonLineHeight, forKey: .buttonLineHeight)
        try container.encodeIfPresent(buttonTextAlignment, forKey: .buttonTextAlignment)
        try container.encodeIfPresent(buttonFontUrl, forKey: .buttonFontUrl)
        try container.encodeIfPresent(buttonLink, forKey: .buttonLink)
        try container.encode(buttonStyle, forKey: .buttonStyle)
        try container.encode(buttonEnabled, forKey: .buttonEnabled)
        try container.encodeIfPresent(buttonType, forKey: .buttonType)
        try container.encodeIfPresent(buttonHasBorder, forKey: .buttonHasBorder)
        try container.encodeIfPresent(fontData, forKey: .fontData)
    }
    
    public enum CodingKeys: String, CodingKey {
        // Button
        case buttonText = "button_text"
        case buttonBackgroundColor = "button_background_color"
        case buttonTextColor = "button_text_color"
        case buttonLayout = "button_width"
        case buttonCornerRadius = "button_corner_radius"
        case buttonMargin = "button_margin"
        case buttonBorderWidth = "button_border_width"
        case buttonFontSize = "button_font_size"
        case buttonLineHeight = "button_line_height"
        case buttonPadding = "button_padding"
        case buttonBorderColor = "button_border_color"
        case buttonTextAlignment = "button_align"
        case buttonFontUrl = "button_font_url"
        case buttonLink = "button_link"
        case buttonStyle = "button_format"
        case buttonEnabled = "button_enabled"
        case buttonType = "button_type"
        case buttonHasBorder = "button_has_border"
        case fontData
    }
}

public struct RichInAppMessagePayload: Codable, Sendable {

    // Layout
    public let layoutConfig: InAppLayoutConfig
    public let layoutBackgroundColor: String?
    public let layoutContainerMargin: String?
    public let layoutContainerPadding: String?
    public let layoutCornerRadius: String?
    public let layoutButtonAlign: String?
    public let layoutTextPosition: String?
    public let layoutMessagePosition: String?

    // Image
    public var imageConfig: InAppImageComponentConfig
    public let imageUrl: String?
    public let imageAspectRationWidth: String?
    public let imageAspectRationHeight: String?
    public let imageMargin: String?
    public let imageOverlayColor: String?
    public let imageSize: String?
    public let imageObjectFit: String?
    public let imageCornerRadius: String?
    public let imageIsVisible: Bool
    public let imageIsOverlay: Bool

    // Close button
    public var closeConfig: InAppCloseButtonConfig
    public let closeMargin: String?
    public let closeImageURL: String?
    public let closeBackgroundColor: String?
    public let closeIconColor: String?
    public let closeVisibility: Bool

    // Title label
    public var titleConfig: InAppLabelConfig
    public var titleText: String?
    public var titleSize: String?
    public var titleStyle: [String]
    public var titleAlignment: String?
    public var titleColor: String?
    public var titleLineHeight: String?
    public var titleCustomFont: String?
    public var titleIsVisible: Bool
    public var titlePadding: String?
    public var titleFontData: InAppButtonFontData?

    // Body label
    public var bodyConfig: InAppBodyLabelConfig
    public var bodyText: String?
    public var bodySize: String?
    public var bodyStyle: [String]
    public var bodyAlignment: String?
    public var bodyColor: String?
    public var bodyLineHeight: String?
    public var bodyCustomFont: String?
    public var bodyIsVisible: Bool
    public var bodyPadding: String?
    public var bodyFontData: InAppButtonFontData?

    // Buttons
    public var buttons: [InAppButtonPayload]


    // Implementace encode(to:) pro vlastní serializaci
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Layout
        try container.encodeIfPresent(layoutBackgroundColor, forKey: .layoutBackgroundColor)
        try container.encodeIfPresent(layoutContainerMargin, forKey: .layoutContainerMargin)
        try container.encodeIfPresent(layoutContainerPadding, forKey: .layoutContainerPadding)
        try container.encodeIfPresent(layoutCornerRadius, forKey: .layoutCornerRadius)
        try container.encodeIfPresent(layoutButtonAlign, forKey: .layoutButtonAlign)
        try container.encodeIfPresent(layoutTextPosition, forKey: .layoutTextPosition)
        try container.encodeIfPresent(layoutMessagePosition, forKey: .layoutMessagePosition)
        
        // Image
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(imageAspectRationWidth, forKey: .imageAspectRationWidth)
        try container.encodeIfPresent(imageAspectRationHeight, forKey: .imageAspectRationHeight)
        try container.encodeIfPresent(imageMargin, forKey: .imageMargin)
        try container.encodeIfPresent(imageOverlayColor, forKey: .imageOverlayColor)
        try container.encodeIfPresent(imageSize, forKey: .imageSize)
        try container.encodeIfPresent(imageObjectFit, forKey: .imageObjectFit)
        try container.encodeIfPresent(imageCornerRadius, forKey: .imageCornerRadius)
        try container.encode(imageIsVisible, forKey: .imageIsVisible)
        try container.encode(imageIsOverlay, forKey: .imageIsOverlay)
        
        // Close button
        try container.encodeIfPresent(closeMargin, forKey: .closeMargin)
        try container.encodeIfPresent(closeImageURL, forKey: .closeImageURL)
        try container.encodeIfPresent(closeBackgroundColor, forKey: .closeBackgroundColor)
        try container.encodeIfPresent(closeIconColor, forKey: .closeIconColor)
        try container.encode(closeVisibility, forKey: .closeVisibility)
        
        // Title label
        try container.encodeIfPresent(titleText, forKey: .titleText)
        try container.encodeIfPresent(titleSize, forKey: .titleSize)
        try container.encode(titleStyle, forKey: .titleStyle)
        try container.encodeIfPresent(titleAlignment, forKey: .titleAlignment)
        try container.encodeIfPresent(titleColor, forKey: .titleColor)
        try container.encodeIfPresent(titleLineHeight, forKey: .titleLineHeight)
        try container.encodeIfPresent(titleCustomFont, forKey: .titleCustomFont)
        try container.encode(titleIsVisible, forKey: .titleIsVisible)
        try container.encodeIfPresent(titlePadding, forKey: .titlePadding)
        try container.encodeIfPresent(titleFontData, forKey: .titleFontData)
        
        // Body label
        try container.encodeIfPresent(bodyText, forKey: .bodyText)
        try container.encodeIfPresent(bodySize, forKey: .bodySize)
        try container.encode(bodyStyle, forKey: .bodyStyle)
        try container.encodeIfPresent(bodyAlignment, forKey: .bodyAlignment)
        try container.encodeIfPresent(bodyColor, forKey: .bodyColor)
        try container.encodeIfPresent(bodyLineHeight, forKey: .bodyLineHeight)
        try container.encodeIfPresent(bodyCustomFont, forKey: .bodyCustomFont)
        try container.encode(bodyIsVisible, forKey: .bodyIsVisible)
        try container.encodeIfPresent(bodyPadding, forKey: .bodyPadding)
        try container.encodeIfPresent(bodyFontData, forKey: .bodyFontData)
        
        // Buttons
        try container.encode(buttons, forKey: .buttons)
    }

    public enum CodingKeys: String, CodingKey {
        // Buttons
        case buttons = "buttons"

        // Image
        case imageUrl = "image_url"
        case imageAspectRationWidth = "image_aspect_ratio_width"
        case imageAspectRationHeight = "image_aspect_ratio_height"
        case imageObjectFit = "image_object_fit"
        case imageSize = "image_size"
        case imageMargin = "image_margin"
        case imageOverlayColor = "overlay_color"
        case imageCornerRadius = "image_corner_radius"
        case imageIsVisible = "image_enabled"
        case imageIsOverlay = "image_overlay_enabled"

        // Close button
        case closeMargin = "close_button_margin"
        case closeImageURL = "close_button_image_url"
        case closeBackgroundColor = "close_button_background_color"
        case closeIconColor = "close_button_color"
        case closeVisibility = "close_button_enabled"

        // Title label
        case titleText = "title"
        case titleSize = "title_text_size"
        case titleStyle = "title_format"
        case titleAlignment = "title_align"
        case titleColor = "title_text_color"
        case titleLineHeight = "title_line_height"
        case titleCustomFont = "title_font_url"
        case titleIsVisible = "title_enabled"
        case titlePadding = "title_padding"
        case titleFontData

        // Body label
        case bodyText = "body_text"
        case bodySize = "body_text_size"
        case bodyStyle = "body_format"
        case bodyAlignment = "body_align"
        case bodyColor = "body_text_color"
        case bodyLineHeight = "body_line_height"
        case bodyCustomFont = "body_font_url"
        case bodyIsVisible = "body_enabled"
        case bodyPadding = "body_padding"
        case bodyFontData

        // Layout
        case layoutBackgroundColor = "background_color"
        case layoutContainerMargin = "container_margin"
        case layoutContainerPadding = "container_padding"
        case layoutCornerRadius = "container_corner_radius"
        case layoutButtonAlign = "buttons_align"
        case layoutTextPosition = "text_position"
        case layoutMessagePosition = "message_position"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        func extractFont(base64: String?, size: CGFloat?) -> UIFont? {
            if let base64 = base64,
               let data = Data(base64Encoded: base64),
               let dataProvider = CGDataProvider(data: data as CFData),
               let cgFont = CGFont(dataProvider) {
                var error: Unmanaged<CFError>?
                if CTFontManagerRegisterGraphicsFont(cgFont, &error) {
                    var font: UIFont?
                    if let fontName = cgFont.postScriptName as? String {
                        font = UIFont(name: fontName, size: size ?? 13)
                    }
                    CTFontManagerUnregisterGraphicsFont(cgFont, &error)
                    return font
                }
            }
            return nil
        }

        func extractFont(url: URL, fontSize: String?, size: CGFloat?) -> InAppButtonFontData? {
            if let data = try? Data(contentsOf: url),
               let dataProvider = CGDataProvider(data: data as CFData),
               let cgFont = CGFont(dataProvider) {
                var fontData: InAppButtonFontData = .init()
                var error: Unmanaged<CFError>?
                if CTFontManagerRegisterGraphicsFont(cgFont, &error) {
                    let size = size ?? fontSize?.convertPxToFloatWithDefaultValue() ?? 13
                    fontData.fontName = cgFont.postScriptName as? String
                    fontData.fontSize = size
                    fontData.fontData = data.base64EncodedString()
                    if let fontName = cgFont.postScriptName as? String {
                        fontData.loadedFont = UIFont(name: fontName, size: size)
                    }
                    CTFontManagerUnregisterGraphicsFont(cgFont, &error)
                }
                return fontData
            }
            return nil
        }

        buttons = try container.decode([InAppButtonPayload].self, forKey: .buttons)

        // Layout
        self.layoutBackgroundColor = try container.decodeIfPresent(String.self, forKey: .layoutBackgroundColor)
        self.layoutContainerMargin = try container.decodeIfPresent(String.self, forKey: .layoutContainerMargin)
        self.layoutContainerPadding = try container.decodeIfPresent(String.self, forKey: .layoutContainerPadding)
        self.layoutCornerRadius = try container.decodeIfPresent(String.self, forKey: .layoutCornerRadius)
        self.layoutButtonAlign = try container.decodeIfPresent(String.self, forKey: .layoutButtonAlign)
        self.layoutTextPosition = try container.decodeIfPresent(String.self, forKey: .layoutTextPosition)
        self.layoutMessagePosition = try container.decodeIfPresent(String.self, forKey: .layoutMessagePosition)

        var layoutMargin: [InAppButtonEdge] = []
        if let margins = layoutContainerMargin {
            layoutMargin = margins.calculatePaddings()
        }
        var layoutPadding: [InAppButtonEdge] = []
        if let margins = layoutContainerPadding {
            layoutPadding = margins.calculatePaddings()
        }
        layoutConfig = .init(
            backgroundColor: layoutBackgroundColor,
            margin: layoutMargin,
            padding: layoutPadding,
            cornerRadius: layoutCornerRadius?.convertPxToFloatWithDefaultValue() ?? 0,
            buttonsAlign: .init(input: layoutButtonAlign),
            textPosition: .init(input: layoutTextPosition),
            messagePosition: .init(input: layoutMessagePosition)
        )

        // Body label
        self.bodyText = try container.decodeIfPresent(String.self, forKey: .bodyText)
        self.bodySize = try container.decodeIfPresent(String.self, forKey: .bodySize)
        self.bodyStyle = try container.decodeIfPresent([String].self, forKey: .bodyStyle) ?? []
        self.bodyAlignment = try container.decodeIfPresent(String.self, forKey: .bodyAlignment)
        self.bodyColor = try container.decodeIfPresent(String.self, forKey: .bodyColor)
        self.bodyLineHeight = try container.decodeIfPresent(String.self, forKey: .bodyLineHeight)
        self.bodyCustomFont = try container.decodeIfPresent(String.self, forKey: .bodyCustomFont)
        self.bodyIsVisible = try container.decodeIfPresent(Bool.self, forKey: .bodyIsVisible) ?? false
        self.bodyPadding = try container.decodeIfPresent(String.self, forKey: .bodyPadding)

        var bodyMargin: [InAppButtonEdge] = []
        if let margins = try container.decodeIfPresent(String.self, forKey: .bodyPadding) {
            bodyMargin = margins.calculatePaddings()
        }
        var bodyFontData: InAppButtonFontData?
        let bodyFontDataBuffer = try? container.decodeIfPresent(InAppButtonFontData.self, forKey: .bodyFontData)
        var bodyData = bodyFontDataBuffer
        if bodyFontDataBuffer?.fontName != nil && bodyIsVisible {
            bodyData?.loadedFont = extractFont(base64: bodyFontDataBuffer?.fontData, size: bodyFontDataBuffer?.fontSize)
            bodyFontData = bodyData
        } else if let customFont = bodyCustomFont, let url = URL(string: customFont) {
            bodyFontData = extractFont(url: url, fontSize: bodySize, size: nil)
        }
        self.bodyFontData = bodyFontData

        bodyConfig = .init(
            text: bodyText,
            size: bodySize?.convertPxToFloatWithDefaultValue() ?? 0,
            style: bodyStyle.joined(separator: "+").lowercased(),
            alignment: bodyAlignment,
            color: bodyColor,
            lineHeight: bodyLineHeight?.convertPxToFloatWithDefaultValue() ?? 0,
            customFont: bodyCustomFont,
            isVisible: bodyIsVisible,
            padding: bodyMargin,
            fontData: bodyFontData
        )

        // Title label
        self.titleText = try container.decodeIfPresent(String.self, forKey: .titleText)
        self.titleSize = try container.decodeIfPresent(String.self, forKey: .titleSize)
        self.titleStyle = try container.decodeIfPresent([String].self, forKey: .titleStyle) ?? []
        self.titleAlignment = try container.decodeIfPresent(String.self, forKey: .titleAlignment)
        self.titleColor = try container.decodeIfPresent(String.self, forKey: .titleColor)
        self.titleLineHeight = try container.decodeIfPresent(String.self, forKey: .titleLineHeight)
        self.titleCustomFont = try container.decodeIfPresent(String.self, forKey: .titleCustomFont)
        self.titleIsVisible = try container.decodeIfPresent(Bool.self, forKey: .titleIsVisible) ?? false
        self.titlePadding = try container.decodeIfPresent(String.self, forKey: .titlePadding)

        var titleMargin: [InAppButtonEdge] = []
        if let margins = try container.decodeIfPresent(String.self, forKey: .titlePadding) {
            titleMargin = margins.calculatePaddings()
        }
        var titleFontData: InAppButtonFontData?
        let titleFontDataBuffer = try? container.decodeIfPresent(InAppButtonFontData.self, forKey: .titleFontData)
        var titleData = titleFontDataBuffer
        if titleFontDataBuffer?.fontName != nil && titleIsVisible {
            titleData?.loadedFont = extractFont(base64: titleFontDataBuffer?.fontData, size: titleFontDataBuffer?.fontSize)
            titleFontData = titleData
        } else if let customFont = titleCustomFont, let url = URL(string: customFont) {
            titleFontData = extractFont(url: url, fontSize: titleSize, size: nil)
        }
        self.titleFontData = titleFontData

        titleConfig = .init(
            text: titleText,
            size: titleSize?.convertPxToFloatWithDefaultValue() ?? 0,
            style: titleStyle.joined(separator: "+").lowercased(),
            alignment: titleAlignment,
            color: titleColor,
            lineHeight: titleLineHeight?.convertPxToFloatWithDefaultValue() ?? 0,
            customFont: titleCustomFont,
            isVisible: titleIsVisible,
            padding: titleMargin,
            fontData: titleFontData
        )

        // Close button
        self.closeMargin = try container.decodeIfPresent(String.self, forKey: .closeMargin)
        self.closeImageURL = try container.decodeIfPresent(String.self, forKey: .closeImageURL)
        self.closeBackgroundColor = try container.decodeIfPresent(String.self, forKey: .closeBackgroundColor)
        self.closeIconColor = try container.decodeIfPresent(String.self, forKey: .closeIconColor)
        self.closeVisibility = try container.decodeIfPresent(Bool.self, forKey: .closeVisibility) ?? false

        var closeMargin: [InAppButtonEdge] = []
        if let margins = try container.decodeIfPresent(String.self, forKey: .closeMargin) {
            closeMargin = margins.calculatePaddings()
        }
        closeConfig = .init(
            margin: closeMargin,
            imageURL: closeImageURL,
            backgroundColor: closeBackgroundColor,
            iconColor: closeIconColor,
            visibility: closeVisibility
        )

        // Image
        self.imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        self.imageAspectRationWidth =  try container.decodeIfPresent(String.self, forKey: .imageAspectRationWidth)
        self.imageAspectRationHeight = try container.decodeIfPresent(String.self, forKey: .imageAspectRationHeight)
        self.imageObjectFit = try container.decodeIfPresent(String.self, forKey: .imageObjectFit)
        self.imageSize = try container.decodeIfPresent(String.self, forKey: .imageSize)
        self.imageMargin = try container.decodeIfPresent(String.self, forKey: .imageMargin)
        self.imageOverlayColor = try container.decodeIfPresent(String.self, forKey: .imageOverlayColor)
        self.imageCornerRadius = try container.decodeIfPresent(String.self, forKey: .imageCornerRadius)
        self.imageIsVisible = try container.decodeIfPresent(Bool.self, forKey: .imageIsVisible) ?? false
        self.imageIsOverlay = try container.decodeIfPresent(Bool.self, forKey: .imageIsOverlay) ?? false

        var aspectRatioSize: CGSize?
        if let width = imageAspectRationWidth?.convertPxToFloatWithDefaultValue(),
           let height = imageAspectRationHeight?.convertPxToFloatWithDefaultValue() {
            aspectRatioSize = .init(width: width, height: height)
        }
        var imageMargin: [InAppButtonEdge] = []
        if let margins = try container.decodeIfPresent(String.self, forKey: .imageMargin) {
            imageMargin = margins.calculatePaddings()
        }
        imageConfig = .init(
            url: URL(string: imageUrl ?? ""),
            size: .init(
                aspectRation: aspectRatioSize,
                size: imageSize,
                objectFit: imageObjectFit
            ),
            margin: imageMargin,
            overlayColor: imageOverlayColor,
            cornerRadius: imageCornerRadius?.convertPxToFloatWithDefaultValue() ?? 0,
            isVisible: imageIsVisible,
            isOverlay: imageIsOverlay
        )
    }
}

public struct InAppMessagePayload: Codable, Equatable, Sendable {
    public let imageUrl: String?
    public let title: String?
    public let titleTextColor: String?
    public let titleTextSize: String?
    public let bodyText: String?
    public let bodyTextColor: String?
    public let bodyTextSize: String?
    public var buttons: [InAppMessagePayloadButton]?
    public let backgroundColor: String?
    public let closeButtonColor: String?
    public let messagePosition: String?
    public let textPosition: String?
    public let textOverImage: Bool?

    enum CodingKeys: String, CodingKey {
        case imageUrl = "image_url"
        case title = "title"
        case titleTextColor = "title_text_color"
        case titleTextSize = "title_text_size"
        case bodyText = "body_text"
        case bodyTextColor = "body_text_color"
        case bodyTextSize = "body_text_size"
        case buttons = "buttons"
        case backgroundColor = "background_color"
        case closeButtonColor = "close_button_color"
        case messagePosition = "message_position"
        case textPosition = "text_position"
        case textOverImage = "text_over_image"
    }

    public init(imageUrl: String?, title: String?, titleTextColor: String?, titleTextSize: String?, bodyText: String?, bodyTextColor: String?, bodyTextSize: String?, buttons: [InAppMessagePayloadButton]?, backgroundColor: String?, closeButtonColor: String?, messagePosition: String?, textPosition: String?, textOverImage: Bool?) {
        self.imageUrl = imageUrl
        self.title = title
        self.titleTextColor = titleTextColor
        self.titleTextSize = titleTextSize
        self.bodyText = bodyText
        self.bodyTextColor = bodyTextColor
        self.bodyTextSize = bodyTextSize
        self.buttons = buttons
        self.backgroundColor = backgroundColor
        self.closeButtonColor = closeButtonColor
        self.messagePosition = messagePosition
        self.textPosition = textPosition
        self.textOverImage = textOverImage
    }
    
}

public struct InAppMessagePayloadButton: Codable, Equatable, Sendable {
    public let buttonText: String?
    public let rawButtonType: String?
    public var buttonType: InAppMessageButtonType {
        return InAppMessageButtonType(rawValue: rawButtonType ?? "") ?? .deeplink
    }
    public let buttonLink: String?
    public let buttonTextColor: String?
    public let buttonBackgroundColor: String?

    enum CodingKeys: String, CodingKey {
        case buttonText = "button_text"
        case rawButtonType = "button_type"
        case buttonLink = "button_link"
        case buttonTextColor = "button_text_color"
        case buttonBackgroundColor = "button_background_color"
    }

    public init(buttonText: String?, rawButtonType: String?, buttonLink: String?, buttonTextColor: String?, buttonBackgroundColor: String?) {
        self.buttonText = buttonText
        self.rawButtonType = rawButtonType
        self.buttonLink = buttonLink
        self.buttonTextColor = buttonTextColor
        self.buttonBackgroundColor = buttonBackgroundColor
    }
    
    public init(closeConfig: InAppCloseButtonConfig) {
        self.buttonText = "close"
        self.rawButtonType = "close"
        self.buttonLink = nil
        self.buttonTextColor = closeConfig.iconColor
        self.buttonBackgroundColor = closeConfig.backgroundColor
    }
}

public enum InAppMessageButtonType: String {
    case cancel
    case deeplink = "deep-link"
    case browser
}
