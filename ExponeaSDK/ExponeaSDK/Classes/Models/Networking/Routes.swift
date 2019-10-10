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
    case customerRecommendation
    case customerAttributes
    case customerEvents
    case banners
    case personalization
    case campaignClick
    case consents

    var method: HTTPMethod {
        switch self {
        case .consents: return .get
        default: return .post
        }
    }
}
