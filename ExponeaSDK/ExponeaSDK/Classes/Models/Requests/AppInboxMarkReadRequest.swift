//
//  AppInboxMarkReadRequest.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 27/10/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//

import Foundation

struct AppInboxMarkReadRequest: Codable, RequestParametersType {
    var messageIds: [String]
    var parameters: [String: JSONValue] {
        return [
            "message_ids": .array(messageIds.map({ v in v.jsonValue }))
        ]
    }
}
