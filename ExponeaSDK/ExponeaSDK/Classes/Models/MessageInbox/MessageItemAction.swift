//
//  MessageItemAction.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 25/10/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//

import Foundation

public struct MessageItemAction: Codable, Equatable {
    public let action: String?
    public let title: String?
    public let url: String?

    public init(action: String?, title: String?, url: String?) {
        self.action = action
        self.title = title
        self.url = url
    }

    public var type: MessageItemActionType {
        return MessageItemActionType(rawValue: action ?? "app") ?? .noAction
    }
}

public enum MessageItemActionType: String {
    case app = "app"
    case browser = "browser"
    case deeplink = "deeplink"
    case noAction = "no_action"
}
