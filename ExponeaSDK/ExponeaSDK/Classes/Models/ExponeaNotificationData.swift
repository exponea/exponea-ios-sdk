//
//  ExponeaNotificationData.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 28/11/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

struct ExponeaNotificationData: Codable {
    let campaignId: String
    let campaignName: String
    let actionId: Int
    
    var properties: [String: JSONValue] {
        return [
            "campaign_id" : .string(campaignId),
            "campaign_name" : .string(campaignName),
            "action_id" : .int(actionId)
        ]
    }
}
