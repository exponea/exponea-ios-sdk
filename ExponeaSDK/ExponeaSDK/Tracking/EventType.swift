//
//  EventType.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 11/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// <#Description#>
///
/// - install: <#install description#>
/// - sessionStart: <#sessionStart description#>
/// - sessionEnd: <#sessionEnd description#>
/// - custom: <#custom description#>
enum EventType {
    /// Tracking Events
    case install
    case sessionStart
    case sessionEnd
    case trackEvent
    case trackCustomer
    case payment
    /// Fetching Events
    case fetchProperty
    case fetchId
    case fetchSegmentation
    case fetchExpression
    case fetchPrediction
    case fetchRecommendation
    case fetchAttributes
    case fetchEvents
    case fetchAllProperties
    case fetchAllCustomers
    case fetchAnonymize
    /// Token Events
    case revokeToken
    case renewToken
}

// TODO: add other events
