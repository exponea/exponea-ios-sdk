//
//  ConsentsResponse.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 11/06/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

/// The response returned when fetching consents.
public struct ConsentsResponse: Codable {
    /// Contains an array of consent categories.
    public let consents: [Consent]
    /// If the request was successful.
    public let success: Bool
}

private extension ConsentsResponse {
    enum CodingKeys: String, CodingKey {
        case consents = "results"
        case success
    }
}
