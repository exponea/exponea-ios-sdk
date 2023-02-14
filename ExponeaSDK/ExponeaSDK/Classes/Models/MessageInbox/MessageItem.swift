//
//  MessageItem.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 10/10/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//

import Foundation

public struct MessageItem: Codable, Equatable {

    public let id: String
    public let type: String
    public var read: Bool
    public let rawReceivedTime: Double?
    public let rawContent: [String: JSONValue]?

    internal var customerId: String?
    internal var syncToken: String?

    public var hasTrackingConsent: Bool {
        return content?.hasTrackingConsent ?? true
    }

    public var receivedTime: Date {
        guard let receivedTimeSeconds = rawReceivedTime else {
            return Date()
        }
        return Date(timeIntervalSince1970: receivedTimeSeconds)
    }

    public var content: MessageItemContent? {
        switch type {
        case "push": return AppInboxParser.parseFromPushNotification(rawContent)
        case "html": return AppInboxParser.parseFromHtmlMessage(rawContent ?? [:])
        default:
            Exponea.logger.log(.error, message: "AppInbox message has unsupported type \(type)")
            return nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case read = "is_read"
        case rawReceivedTime = "create_time"
        case rawContent = "content"
        case syncToken
        case customerId
    }

    public static func == (lhs: MessageItem, rhs: MessageItem) -> Bool {
        lhs.id == rhs.id
    }

    public init(
        id: String,
        type: String,
        read: Bool,
        rawReceivedTime: Double?,
        rawContent: [String: JSONValue]?
    ) {
        self.id = id
        self.type = type
        self.read = read
        self.rawReceivedTime = rawReceivedTime
        self.rawContent = rawContent
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try? container.decode(String.self, forKey: .id)
        let type = try? container.decode(String.self, forKey: .type)
        let read = try? container.decode(Bool.self, forKey: .read)
        let receivedTime = try? container.decode(Double.self, forKey: .rawReceivedTime)
        let content = try? container.decode([String: JSONValue].self, forKey: .rawContent)
        self.init(
            id: id ?? "",
            type: type ?? "unknown",
            read: read ?? false,
            rawReceivedTime: receivedTime,
            rawContent: content
        )
        self.syncToken = try? container.decodeIfPresent(String.self, forKey: .syncToken)
        self.customerId = try? container.decodeIfPresent(String.self, forKey: .customerId)
    }
}
