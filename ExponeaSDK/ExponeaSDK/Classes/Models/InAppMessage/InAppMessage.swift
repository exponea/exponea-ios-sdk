//
//  InAppMessage.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 28/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

struct InAppMessage: Codable, Equatable {
    public let id: String
    public let name: String
    public let messageType: String
    public let frequency: String
    public let payload: InAppMessagePayload
    public let variantId: Int
    public let variantName: String
    public let trigger: InAppMessageTrigger
    public let dateFilter: DateFilter

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name
        case messageType = "message_type"
        case frequency = "frequency"
        case payload
        case variantId = "variant_id"
        case variantName = "variant_name"
        case trigger
        case dateFilter = "date_filter"
    }
}

struct InAppMessageTrigger: Codable, Equatable {
    public let type: String?
    public let eventType: String?

    enum CodingKeys: String, CodingKey {
        case type
        case eventType = "event_type"
    }
}
