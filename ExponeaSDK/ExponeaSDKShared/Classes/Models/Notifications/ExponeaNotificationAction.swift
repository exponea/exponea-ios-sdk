//
//  ExponeaNotificationAction.swift
//  ExponeaSDKShared
//
//  Created by Dominik Hadl on 19/12/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import UserNotifications

public struct ExponeaNotificationAction: Codable {
    public let title: String
    public let action: ExponeaNotificationActionType
    public let url: String?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        action = try container.decode(ExponeaNotificationActionType.self, forKey: .action)
        url = try container.decodeIfPresent(String.self, forKey: .url)
    }

    public static func createNotificationAction(type: ExponeaNotificationActionType,
                                                title: String, index: Int) -> UNNotificationAction {
        return UNNotificationAction(
            identifier: type.identifier + "_" + String(index),
            title: title,
            options: [.foreground]
        )
    }
}
