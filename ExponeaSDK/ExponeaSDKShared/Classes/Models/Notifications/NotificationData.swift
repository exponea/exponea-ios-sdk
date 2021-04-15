//
//  NotificationData.swift
//  ExponeaSDKShared
//
//  Created by Dominik Hadl on 28/11/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

public struct NotificationData: Codable {
    public let eventType: String?
    public let campaignId: String?
    public let campaignName: String?
    public let actionId: Int?
    public let actionName: String?
    public let actionType: String?
    public let campaignPolicy: String?
    public let platform: String?
    public let language: String?
    public let recipient: String?
    public let subject: String?
    public var timestamp: Double
    public let sentTimestamp: Double?
    public let type: String?
    public let campaignData: CampaignData

    public init(
        eventType: String? = nil,
        campaignId: String? = nil,
        campaignName: String? = nil,
        actionId: Int? = nil,
        actionName: String? = nil,
        actionType: String? = nil,
        campaignPolicy: String? = nil,
        platform: String? = nil,
        language: String? = nil,
        recipient: String? = nil,
        subject: String? = nil,
        timestamp: Double = Date().timeIntervalSince1970,
        sentTimestamp: Double? = nil,
        type: String? = nil,
        campaignData: CampaignData = CampaignData()
    ) {
        self.eventType = eventType
        self.campaignId = campaignId
        self.campaignName = campaignName
        self.actionId = actionId
        self.actionName = actionName
        self.actionType = actionType
        self.campaignPolicy = campaignPolicy
        self.platform = platform
        self.language = language
        self.recipient = recipient
        self.subject = subject
        self.timestamp = timestamp
        self.sentTimestamp = sentTimestamp
        self.type = type
        self.campaignData = campaignData
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        eventType = try? container.decode(String.self, forKey: .eventType)
        campaignId = try? container.decode(String.self, forKey: .campaignId)
        campaignName = try? container.decode(String.self, forKey: .campaignName)
        actionId = try? container.decode(Int.self, forKey: .actionId)
        actionName = try? container.decode(String.self, forKey: .actionName)
        actionType = try? container.decode(String.self, forKey: .actionType)
        campaignPolicy = try? container.decode(String.self, forKey: .campaignPolicy)
        platform = try? container.decode(String.self, forKey: .platform)
        language = try? container.decode(String.self, forKey: .language)
        recipient = try? container.decode(String.self, forKey: .recipient)
        subject = try? container.decode(String.self, forKey: .subject)
        timestamp = (try? container.decode(Double.self, forKey: .timestamp)) ?? Date().timeIntervalSince1970
        sentTimestamp = try? container.decode(Double.self, forKey: .sentTimestamp)
        type = try? container.decode(String.self, forKey: .type)
        campaignData = (try? container.decode(CampaignData.self, forKey: .campaignData)) ?? CampaignData()
    }

    public static func deserialize(
        attributes: [String: Any],
        campaignData: [String: Any]
    ) -> NotificationData? {
        var allData = attributes
        allData["campaign_data"] = campaignData
        guard let data = try? JSONSerialization.data(withJSONObject: allData, options: []) else {
            return nil
        }
        return deserialize(from: data)
    }

    public static func deserialize(from data: Data) -> NotificationData? {
        return try? JSONDecoder.snakeCase.decode(NotificationData.self, from: data)
    }

    public func serialize() -> Data? {
        return try? JSONEncoder.snakeCase.encode(self)
    }
}
