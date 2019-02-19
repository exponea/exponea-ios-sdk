//
//  NotificationData.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 28/11/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

public struct NotificationData: Codable {
    let campaignId: String
    let campaignName: String
    let actionId: Int
    let timestamp: Date

    init(campaignId: String, campaignName: String, actionId: Int, timestamp: Date = Date()) {
        self.campaignId = campaignId
        self.campaignName = campaignName
        self.actionId = actionId
        self.timestamp = timestamp
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        campaignId = try container.decode(String.self, forKey: .campaignId)
        campaignName = try container.decode(String.self, forKey: .campaignName)
        actionId = try container.decode(Int.self, forKey: .actionId)
        timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp) ?? Date()
    }
}
