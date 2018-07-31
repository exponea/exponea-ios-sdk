//
//  MockData.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 31/07/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

@testable import ExponeaSDK

struct MockData {
    
    let customerIds: [String: JSONValue] = [
        "registered": .string("marian.galik@exponea.com")]
    
    let properties: [String: JSONValue] = [
        "properties": .dictionary([
            "first_name": .string("Marian"),
            "last_name": .string("Galik"),
            "email": .string("marian.galik@exponea.com")])
    ]
    
    let eventTypes: [String] = ["install",
                                "session_start",
                                "session_end"]
    
    let items: [String: JSONValue] = [
        "items": .dictionary([
            "item01": .int(1),
            "item02": .int(2)
        ])
    ]
    
    let recommendRequest = RecommendationRequest(type: "recommendation",
                                                 id: "592ff585fb60094e02bfaf6a",
                                                 size: 10,
                                                 strategy: "winner",
                                                 knowItems: false,
                                                 anti: false,
                                                 items: nil)
    
    let attributesDesc = AttributesDescription(key: "id",
                                               value: "registered",
                                               identificationKey: "property",
                                               identificationValue: "first_name")
    
    let eventRequest = EventsRequest(eventTypes: ["install",
                                                  "session_start",
                                                  "session_end"],
                                     sortOrder: nil,
                                     limit: nil,
                                     skip: nil)
    
    let customerExportRequest = CustomerExportRequest(attributes: nil,
                                                      filter: nil,
                                                      executionTime: nil,
                                                      timezone: nil,
                                                      responseFormat: ExportFormat.csv)
    
    
}
