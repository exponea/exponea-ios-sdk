//
//  TrackMockData.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 13/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

@testable import ExponeaSDK

// Mocking data for tracking tests
class TrackMockData {
    let customerId = KeyValueItem(key: "registered", value: "john.doe@exponea.com")
    let properties = [KeyValueItem(key: "product_name", value: "iPad"),
                      KeyValueItem(key: "price", value: 999.99)]
    let timestamp = NSDate().timeIntervalSince1970
}
