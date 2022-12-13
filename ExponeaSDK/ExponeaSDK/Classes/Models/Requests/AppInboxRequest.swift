//
//  AppInboxRequest.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 26/10/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//

import Foundation

struct AppInboxRequest: Codable, RequestParametersType {
    var syncToken: String?
    var parameters: [String: JSONValue] {
        guard let syncToken = syncToken else {
            return [:]
        }
        return [
            "sync_token": syncToken.jsonValue
        ]
    }
}
