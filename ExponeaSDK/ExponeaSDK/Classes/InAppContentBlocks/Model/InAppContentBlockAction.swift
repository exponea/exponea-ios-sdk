//
//  InAppContentBlockAction.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 08/12/2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation

public struct InAppContentBlockAction: Codable {
    public let name: String?
    public let url: String?
    public let type: InAppContentBlockActionType

    public init(name: String?, url: String?, type: InAppContentBlockActionType) {
        self.name = name
        self.url = url
        self.type = type
    }
}

public enum InAppContentBlockActionType: String, Codable {
    case deeplink
    case browser
    case close
    case unknown

    init(input: String?) {
        switch input?.lowercased() {
        case "cancel":
            self = .close
        case "deep-link":
            self = .deeplink
        case "browser":
            self = .browser
        default:
            self = .unknown
        }
    }
}
