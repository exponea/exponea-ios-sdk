//
//  FetchMockData.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 18/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

@testable import ExponeaSDK

class FetchMockData {
    let customerId: [String: JSONConvertible] = ["registered": "rito@nodesagency.com"]
    let customerData = FetchEventsRequest(eventTypes: ["session_start", "install"],
                                      sortOrder: "asc",
                                      limit: 1,
                                      skip: 100)
    let recommendation = CustomerRecommendation(type: "recommendation",
                                                id: "592ff585fb60094e02bfaf6a",
                                                size: nil,
                                                strategy: nil,
                                                knowItems: nil,
                                                anti: nil,
                                                items: nil)
}
