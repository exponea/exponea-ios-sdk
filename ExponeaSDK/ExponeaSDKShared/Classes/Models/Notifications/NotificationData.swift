//
//  NotificationData.swift
//  ExponeaSDKShared
//
//  Created by Dominik Hadl on 28/11/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

public struct NotificationData: Codable {
    public let attributes: [String: JSONValue]
    public var campaignData: CampaignData
    public var eventType: String?
    public var timestamp: Double
    public var sentTimestamp: Double?
    public var campaignName: String?

    public init(
        attributes: [String: JSONValue] = [String: JSONValue](),
        campaignData: CampaignData = CampaignData(),
        timestamp: Double = Date().timeIntervalSince1970) {
        self.attributes = attributes
        self.campaignData = campaignData
        self.timestamp = timestamp
        if let eventTypeAttribute = attributes["event_type"] {
            self.eventType = eventTypeAttribute.jsonConvertible as? String
        }
        if let sentTimestampAttribute = attributes["sent_timestamp"] {
            self.sentTimestamp = sentTimestampAttribute.jsonConvertible as? Double
        }
        if let campaignNameAttribute = attributes["campaign_name"] {
            self.campaignName = campaignNameAttribute.jsonConvertible as? String
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let attributes = (try? container.decode([String: JSONValue].self, forKey: .attributes)) ?? [String: JSONValue]()
        let campaignData = (try? container.decode(CampaignData.self, forKey: .campaignData)) ?? CampaignData()
        let timestamp = (try? container.decode(Double.self, forKey: .timestamp)) ?? Date().timeIntervalSince1970
        self.init(attributes: attributes, campaignData: campaignData, timestamp: timestamp)
    }

    public static func deserialize(
        attributes: [String: Any],
        campaignData: [String: Any]
    ) -> NotificationData? {
        var allData = [String: Any]()
        allData["attributes"] = attributes
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
