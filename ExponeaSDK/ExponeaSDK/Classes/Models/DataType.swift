//
//  DataType.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 18/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// Data types that can be associated with tracked events (described in `EventType`).
///
/// - projectToken
/// - customerId
/// - properties
/// - timestamp
/// - eventType
public enum DataType {

    /// The token of the project that the tracking should be uploaded to.
    case projectToken(String)

    /// Identifier of your customer, can be anything from an email to UUIDs.
    case customerIds([String: JSONValue])

    /// Custom properties that you would like to add to the tracking event,
    /// these can include any relevant information for you.
    case properties([String: JSONValue])

    /// Timestamp of the tracked event in UNIX epoch time, if value is `nil` current date is used.
    case timestamp(Double?)

    /// For some tracked events you can also provide an event type
    case eventType(String)

    case pushNotificationToken(String)
}
