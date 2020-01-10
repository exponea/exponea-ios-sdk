//
//  RecommendationRequest.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 11/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

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
