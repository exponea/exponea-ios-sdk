//
//  RecommendationRequest.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 11/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

@available(*, deprecated, message: "Please use RecommendationsStreamRequest instead.")
struct RecommendationRequest: RequestParametersType {
    let options: RecommendationOptions

    var parameters: [String: JSONValue] {
        return [
            "attributes": .array([
                .dictionary(options.parameters)
            ])
        ]
    }
}
