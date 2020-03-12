//
//  NotificationData.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 28/11/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

public struct NotificationData: Codable {
    let eventType: String?
    let campaignId: String?
    let campaignName: String?
    let actionId: Int?
    let actionName: String?
    let actionType: String?
    let campaignPolicy: String?
    let platform: String?
    let language: String?
    let recipient: String?
    let subject: String?
    let timestamp: Date

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
        timestamp: Date = Date()
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
        timestamp = (try? container.decode(Date.self, forKey: .timestamp)) ?? Date()
    }

    public static func deserialize(from dictionary: [String: Any]) -> NotificationData? {
        guard let data = try? JSONSerialization.data(withJSONObject: dictionary, options: []) else {
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
