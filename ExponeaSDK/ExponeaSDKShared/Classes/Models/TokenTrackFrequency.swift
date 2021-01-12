//
//  TokenTrackFrequency.swift
//  ExponeaSDKShared
//
//  Created by Dominik Hádl on 07/08/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

/// Used to configure when how often should a push notification token be tracked to Exponea.
/// See `Configuration` for ways how to set it up.
///
/// - onTokenChange: Tracked whenever the push token changes.
/// - everyLaunch: Tracked on every launch of the app. Consider data usage/battery life.
/// - daily: Once a day on app launch.
public enum TokenTrackFrequency: String, Codable {
    case onTokenChange
    case everyLaunch
    case daily
}
