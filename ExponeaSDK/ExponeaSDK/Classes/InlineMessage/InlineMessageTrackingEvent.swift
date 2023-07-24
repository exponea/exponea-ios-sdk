//
//  InlineMessageTrackingEvent.swift
//  ExponeaSDK
//
//  Created by Ankmara on 11.06.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation
enum InlineMessageTrackingEvent: Equatable {
    case close
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
        switch self {
        case .close, .click:
            return true
        default:
            return false
        }
    }
}

protocol InlineMessageTrackingDelegate: AnyObject {
    func track(_ event: InlineMessageTrackingEvent, for message: InlineMessageResponse, trackingAllowed: Bool, isUserInteraction: Bool)
}
