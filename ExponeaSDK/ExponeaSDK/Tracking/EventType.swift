//
//  EventType.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 11/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// Types of events that can be tracked.
///
/// - install
/// - sessionStart
/// - sessionEnd
/// - trackEvent
/// - trackCustomer
/// - payment
enum EventType {

    /// Install event is fired only once when the app is first installed.
    case install

    /// Session start event used to mark the start of a session, typically when an app comes to foreground.
    case sessionStart

    /// Session end event used to mark the end of a session, typically when an app goes to background.
    case sessionEnd

    /// Custom event tracking, used to report any custom events that you want.
    case trackEvent

    /// Tracking of customers is used to identify a current customer by some identifier.
    case trackCustomer

    /// Virtual and hard payments can be tracked to better measure conversions for example.
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

extension EventType {
    /// Key used to map values from plist configuration to respective event types.
    /// This value is identical to the enum case name with all leters uppercased and spaces added as '_'.
    var plistKey: String {
        switch self {
        case .install: return "INSTALL"
        case .sessionStart: return "SESSION_START"
        case .sessionEnd: return "SESSION_END"
        case .trackEvent: return "TRACK_EVENT"
        case .trackCustomer: return "TRACK_CUSTOMER"
        case .payment: return "PAYMENT"
        }
    }
}
