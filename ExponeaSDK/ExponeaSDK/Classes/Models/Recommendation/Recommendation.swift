//
//  Recommendation.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 12/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

/// Contains both system and user defined data returned from server.
/// Use your own struct implementing RecommendationUserData protocol, data will be decoded into it
public struct Recommendation<T: RecommendationUserData>: Codable, Equatable {
    public let systemData: RecommendationSystemData
    public let userData: T

    public init(from decoder: Decoder) throws {
        systemData = try RecommendationSystemData.init(from: decoder)
        userData = try T.init(from: decoder)
    }

    public init(systemData: RecommendationSystemData, userData: T) {
        self.systemData = systemData
        self.userData = userData
    }
}

public struct RecommendationSystemData: Codable, Equatable {
    public let engineName: String
    public let itemId: String
    public let recommendationId: String
    public let recommendationVariantId: String?

    public init(
        engineName: String,
        itemId: String,
        recommendationId: String,
        recommendationVariantId: String?
    ) {
        self.engineName = engineName
        self.itemId = itemId
        self.recommendationId = recommendationId
        self.recommendationVariantId = recommendationVariantId
    }

    enum CodingKeys: String, CodingKey {
        case engineName = "engine_name"
        case itemId = "item_id"
        case recommendationId = "recommendation_id"
        case recommendationVariantId = "recommendation_variant_id"
    }
}

/// Implement this protocol with struct containing field of your customer recommendation
public protocol RecommendationUserData: Codable, Equatable {}

/// If you are only interested in recommendation system data, use this as a placeholder
public struct EmptyRecommendationData: RecommendationUserData {}
