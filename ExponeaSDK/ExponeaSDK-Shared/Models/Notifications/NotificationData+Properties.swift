//
//  NotificationData+Properties.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 19/02/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

extension NotificationData {
    var properties: [String: JSONValue] {
        var properties: [String: JSONValue] = [:]
        if let campaignId = campaignId { properties["campaign_id"] = .string(campaignId)}
        if let campaignName = campaignName { properties["campaign_name"] = .string(campaignName)}
        if let actionId = actionId { properties["action_id"] = .int(actionId)}
        if let actionName = actionName { properties["action_name"] = .string(actionName)}
        if let actionType = actionType { properties["action_type"] = .string(actionType)}
        if let campaignPolicy = campaignPolicy { properties["campaign_policy"] = .string(campaignPolicy)}
        if let platform = platform, !platform.isEmpty {
            properties["platform"] = .string(platform)
        } else {
            properties["platform"] = .string("ios")
        }
        if let language = language { properties["language"] = .string(language)}
        if let recipient = recipient { properties["recipient"] = .string(recipient)}
        if let subject = subject { properties["subject"] = .string(subject)}
        campaignData.trackingData.forEach { (key, value) in properties[key] = value }
        return properties
    }
}
