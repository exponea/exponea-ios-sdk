//
//  InAppMessageTrackingDelegate.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 16/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

enum InAppMessageEvent: Equatable {
    case close
    case show
    case click(buttonLabel: String)

    var action: String {
        switch self {
        case .close: return "close"
        case .show: return "show"
        case .click: return "click"
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

protocol InAppMessageTrackingDelegate: class {
    func track(_ event: InAppMessageEvent, for message: InAppMessage)
}
