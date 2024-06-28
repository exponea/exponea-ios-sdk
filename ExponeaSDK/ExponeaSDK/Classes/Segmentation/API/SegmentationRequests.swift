//
//  SegmentationRequests.swift
//  ExponeaSDK
//
//  Created by Ankmara on 19.04.2024.
//  Copyright © 2024 Exponea. All rights reserved.
//

import Foundation

struct SegmentationRequests: Codable, RequestParametersType {
    var cookie: String
    var parameters: [String: JSONValue] {
        [:]
    }
    var requestParameters: [String: Any] {
        [:]
    }
}
