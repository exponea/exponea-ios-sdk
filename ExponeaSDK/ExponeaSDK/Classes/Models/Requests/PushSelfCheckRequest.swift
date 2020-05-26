//
//  PushSelfCheckRequest.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 26/05/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation

struct PushSelfCheckRequest: Codable, RequestParametersType {
    let pushToken: String

    var parameters: [String: JSONValue] {
        return [
            "platform": "ios".jsonValue,
            "push_notification_id": pushToken.jsonValue
        ]
    }
}
