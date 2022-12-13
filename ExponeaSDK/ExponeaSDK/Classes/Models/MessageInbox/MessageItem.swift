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
    public let content: MessageItemContent?
    
    public var hasTrackingConsent: Bool {
        return content?.hasTrackingConsent ?? true
    }
    
    public var receivedTime: Double {
        return (content?.createdAtDate ?? Date()).timeIntervalSince1970
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case read = "is_read"
        case content
    }
    
    public static func == (lhs: MessageItem, rhs: MessageItem) -> Bool {
        lhs.id == rhs.id
    }
}
