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
    let customerId = KeyValueModel(key: "registered", value: "rito@nodesagency.com")
    let customerData = CustomerEvents(eventTypes: ["session_start", "install"],
                                      sortOrder: "asc",
                                      limit: 1,
                                      skip: 100)
}
