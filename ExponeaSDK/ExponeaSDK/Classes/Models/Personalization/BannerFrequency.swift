//
//  BannerFrequency.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 08/06/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// Specifies how many times a banner should be displayed.
public enum BannerFrequency: String, Codable {

    /// Without any limits.
    case always = "always"

    /// Display only one time, never display again.
    case onlyOnce = "only_once"

    /// Display only once per session (only when banner wasn't displayed since last session_start event).
    case oncePerVisit = "once_per_visit"

    /// Display until the customer has interacted with the banner in any way.
    /// Banner event with `interaction` = `true` has been tracked.
    case untilVisitorInteracts = "until_visitor_interacts"
}
