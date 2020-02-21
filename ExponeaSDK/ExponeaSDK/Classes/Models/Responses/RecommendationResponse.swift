//
//  RecommendationResponse.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 11/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

/// Response is returned wrapped, since server allows request for multiple recommendations at once
public struct WrappedRecommendationResponse<T: RecommendationUserData>: Codable {
    public let success: Bool
    public let results: [RecommendationResponse<T>]
}

public struct RecommendationResponse<T: RecommendationUserData>: Codable {
    public let success: Bool
    public let error: String?
    public let value: [Recommendation<T>]?
}
