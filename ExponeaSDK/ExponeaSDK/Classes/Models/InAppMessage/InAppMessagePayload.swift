//
//  InAppMessagePayload.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 28/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

struct InAppMessagePayload: Codable, Equatable {
    public let imageUrl: String
    public let title: String
    public let titleTextColor: String
    public let titleTextSize: String
    public let bodyText: String
    public let bodyTextColor: String
    public let bodyTextSize: String
    public let buttonText: String
    public let buttonType: String
    public let buttonLink: String
    public let buttonTextColor: String
    public let buttonBackgroundColor: String
    public let backgroundColor: String
    public let closeButtonColor: String

    enum CodingKeys: String, CodingKey {
        case imageUrl = "image_url"
        case title = "title"
        case titleTextColor = "title_text_color"
        case titleTextSize = "title_text_size"
        case bodyText = "body_text"
        case bodyTextColor = "body_text_color"
        case bodyTextSize = "body_text_size"
        case buttonText = "button_text"
        case buttonType = "button_type"
        case buttonLink = "button_link"
        case buttonTextColor = "button_text_color"
        case buttonBackgroundColor = "button_background_color"
        case backgroundColor = "background_color"
        case closeButtonColor = "close_button_color"
    }
}
