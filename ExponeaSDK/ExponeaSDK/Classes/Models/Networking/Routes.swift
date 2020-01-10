//
//  Routes.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 20/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// Identification of endpoints for Exponea API
enum Routes {
    case identifyCustomer
    case customEvent
    case customerAttributes
    case banners
    case personalization
    case campaignClick
    case consents
    case inAppMessages

    var method: HTTPMethod {
        switch self {
        case .consents: return .get
        default: return .post
        }
    }
}
