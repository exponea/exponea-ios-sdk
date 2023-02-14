//
//  AppInboxResponse.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 26/10/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//

import Foundation

public struct AppInboxResponse: Codable {
    public let success: Bool
    public let messages: [MessageItem]?
    public let syncToken: String?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.success = try container.decode(Bool.self, forKey: .success)
        self.messages = try container.decodeIfPresent([MessageItem].self, forKey: .messages)
        self.syncToken = try container.decodeIfPresent(String.self, forKey: .syncToken)
    }

    public init(
        success: Bool,
        messages: [MessageItem]?,
        syncToken: String?
    ) {
        self.success = success
        self.messages = messages
        self.syncToken = syncToken
    }

    enum CodingKeys: String, CodingKey {
        case success
        case messages
        case syncToken = "sync_token"
    }
}
