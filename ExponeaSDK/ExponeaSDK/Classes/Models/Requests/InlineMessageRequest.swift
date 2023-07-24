//
//  InlineMessageRequest.swift
//  ExponeaSDK
//
//  Created by Ankmara on 28.08.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation

struct InlineMessageRequest: Codable, RequestParametersType {
    var messageIds: [String]
    var syncToken: String?
    var parameters: [String: JSONValue] {
        [:]
    }
    var requestParameters: [String : Any] {
        ["inline_message_ids": messageIds]
    }
}
