//
//  NotificationData+Properties.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 19/02/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

extension NotificationData {
    var properties: [String: JSONValue] {
        return [
            "campaign_id": .string(campaignId),
            "campaign_name": .string(campaignName),
            "action_id": .int(actionId)
        ]
    }
}
