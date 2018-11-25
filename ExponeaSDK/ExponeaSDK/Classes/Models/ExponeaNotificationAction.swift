//
//  ExponeaNotificationAction.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 25/11/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

public enum ExponeaNotificationAction: String, CaseIterable {
    case openApp = "EXPONEA_APP_OPEN_ACTION"
    case browser = "EXPONEA_BROWSER_ACTION"
    case deeplink = "EXPONEA_DEEPLINK_ACTION"
    case none
    
    var identifier: String {
        switch self {
        case .openApp: return "OPENAPP"
        case .browser: return "BROWSER"
        case .deeplink: return "DEEPLINKG"
        default: return ""
        }
    }
}
