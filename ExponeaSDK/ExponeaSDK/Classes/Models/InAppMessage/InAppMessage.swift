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
    public let payload: InAppMessagePayload
    public let variantId: Int
    public let variantName: String
    public let trigger: InAppMessageTrigger
    public let dateFilter: DateFilter

    enum CodingKeys: String, CodingKey {
        case id = "id", name, payload, variantId = "variant_id", variantName = "variant_name", trigger, dateFilter = "date_filter"
    }
}

/**
 This is temporary, will change in the future.
 We should filter based on events and properties.
 For now, we get objects e.g. {type:"not important" url: "URL"}.
 Check that URL = eventName
 */
struct InAppMessageTrigger: Codable, Equatable {
    public let includePages: [[String: String]]

    enum CodingKeys: String, CodingKey {
        case includePages = "include_pages"
    }
}
