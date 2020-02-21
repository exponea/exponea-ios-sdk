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

    /// Event used for registering the push notifications token of the device with Exponea.
    case registerPushToken = "PUSH_TOKEN"

    /// For tracking that a push notification has been delivered, this has to be done manually using a push service
    /// extension implemented in the host application. See the documentation for more information.
    case pushDelivered = "PUSH_DELIVERED"

    /// For tracking that a push notification has been opened.
    case pushOpened = "PUSH_OPENED"

    case campaignClick = "CAMPAIGN_CLICK"

    // Tracking of in-app message related events
    case banner = "BANNER"
}
