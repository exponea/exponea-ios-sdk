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
    var applicationID: String?
    var parameters: [String: JSONValue] {
        var result = [String: JSONValue]()
        if let syncToken {
            result["sync_token"] = syncToken.jsonValue
        }
        if let applicationID {
            result["application_id"] = applicationID.jsonValue
        }
        return result
    }
}
