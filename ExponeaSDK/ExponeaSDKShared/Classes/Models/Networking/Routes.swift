//
//  Routes.swift
//  ExponeaSDKShared
//
//  Created by Ricardo Tokashiki on 20/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// Identification of endpoints for Exponea API
public enum Routes {
    case identifyCustomer
    case customEvent
    case customerAttributes
    case campaignClick
    case consents
    case inAppMessages
    case pushSelfCheck
    case appInbox
    case appInboxMarkRead
    case inlineMessages
    case personalizedInlineMessages

    public var method: HTTPMethod {
        switch self {
        case .consents, .inlineMessages: return .get
        default: return .post
        }
    }
}
