//
//  InAppContentBlockAction.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 08/12/2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation

public struct InAppContentBlockAction {
    public let name: String?
    public let url: String?
    public let type: InAppContentBlockActionType

    public init(name: String?, url: String?, type: InAppContentBlockActionType) {
        self.name = name
        self.url = url
        self.type = type
    }
}

public enum InAppContentBlockActionType {
    case deeplink
    case browser
    case close
}
