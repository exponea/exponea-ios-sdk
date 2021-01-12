//
//  ExponeaNotificationActionType.swift
//  ExponeaSDKShared
//
//  Created by Dominik Hadl on 25/11/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

public enum ExponeaNotificationActionType: String, Codable {
    case openApp = "app"
    case browser = "browser"
    case deeplink = "deeplink"
    case selfCheck = "self-check"
    case none = ""

    var identifier: String {
        switch self {
        case .openApp: return "EXPONEA_ACTION_APP"
        case .browser: return "EXPONEA_ACTION_BROWSER"
        case .deeplink: return "EXPONEA_ACTION_DEEPLINK"
        default: return ""
        }
    }

    init?(identifier: String) {
        switch identifier {
        case "EXPONEA_ACTION_APP": self = .openApp
        case "EXPONEA_ACTION_BROWSER": self = .browser
        case "EXPONEA_ACTION_DEEPLINK": self = .deeplink
        default: return nil
        }
    }
}
