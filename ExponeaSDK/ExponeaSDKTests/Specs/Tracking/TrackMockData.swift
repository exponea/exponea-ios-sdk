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
    let customerId: [String: JSONConvertible] = ["registered": "john.doe@exponea.com"]
    let properties: [String: JSONConvertible] = ["product_name": "iPad", "price": 999.99]
    let timestamp = NSDate().timeIntervalSince1970
}
