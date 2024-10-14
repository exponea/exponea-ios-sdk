//
//  InAppMessageTrackingDelegate.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 16/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

enum InAppMessageEvent: Equatable {
    case close(buttonLabel: String?)
    case show
    case click(buttonLabel: String, url: String)
    case error(message: String)

    var action: String {
        switch self {
        case .close: return "close"
        case .show: return "show"
        case .click: return "click"
        case .error: return "error"
        }
    }

    var isInteraction: Bool {
        if case .click = self {
            return true
        } else {
            return false
        }
    }
}

protocol InAppMessageTrackingDelegate: AnyObject {
    func track(_ event: InAppMessageEvent, for message: InAppMessage, trackingAllowed: Bool, isUserInteraction: Bool)
}
