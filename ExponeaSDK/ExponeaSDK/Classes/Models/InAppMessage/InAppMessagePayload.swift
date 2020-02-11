//
//  InAppMessagePayload.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 28/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

struct InAppMessagePayload: Codable, Equatable {
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
}

struct InAppMessagePayloadButton: Codable, Equatable {
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
}

enum InAppMessageButtonType: String {
    case cancel
    case deeplink = "deep-link"
}
