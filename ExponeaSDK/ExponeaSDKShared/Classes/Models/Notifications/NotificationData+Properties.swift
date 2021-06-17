//
//  NotificationData+Properties.swift
//  ExponeaSDKShared
//
//  Created by Dominik Hadl on 19/02/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

public extension NotificationData {
    var properties: [String: JSONValue] {
        var properties: [String: JSONValue] = [:]

        attributes.filter { $0.key != "event_type" }.forEach { (key, value) in properties[key] = value }
        campaignData.trackingData.forEach { (key, value) in properties[key] = value }

        if properties["platform"] == nil {
            properties["platform"] = .string("ios")
        }
        return properties
    }
}
