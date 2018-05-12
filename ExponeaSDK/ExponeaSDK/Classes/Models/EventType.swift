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
public enum EventType: String, Decodable {

    /// Install event is fired only once when the app is first installed.
    case install = "INSTALL"

    /// Session start event used to mark the start of a session, typically when an app comes to foreground.
    case sessionStart = "SESSION_START"

    /// Session end event used to mark the end of a session, typically when an app goes to background.
    case sessionEnd = "SESSION_END"

    /// Custom event tracking, used to report any custom events that you want.
    case customEvent = "TRACK_EVENT"

    /// Tracking of customers is used to identify a current customer by some identifier.
    case identifyCustomer = "TRACK_CUSTOMER"

    /// Virtual and hard payments can be tracked to better measure conversions for example.
    case payment = "PAYMENT"
}

extension EventType {
    /// Key used to map values from plist configuration to respective event types.
    /// This value is identical to the enum case name with all leters uppercased and spaces added as '_'.
    var plistKey: String {
        switch self {
        case .install: return "INSTALL"
        case .sessionStart: return "SESSION_START"
        case .sessionEnd: return "SESSION_END"
        case .customEvent: return "TRACK_EVENT"
        case .identifyCustomer: return "TRACK_CUSTOMER"
        case .payment: return "PAYMENT"
        }
    }
}
