//
//  InAppMessagePayload.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 28/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

public struct InAppMessagePayload: Codable, Equatable {
    public let imageUrl: String?
    public let title: String?
    public let titleTextColor: String?
    public let titleTextSize: String?
    public let bodyText: String?
    public let bodyTextColor: String?
    public let bodyTextSize: String?
    public let buttons: [InAppMessagePayloadButton]?
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

public struct InAppMessagePayloadButton: Codable, Equatable {
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
}

public enum InAppMessageButtonType: String {
    case cancel
    case deeplink = "deep-link"
    case browser
}
