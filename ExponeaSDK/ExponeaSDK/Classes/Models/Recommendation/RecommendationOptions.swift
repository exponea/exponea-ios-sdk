//
//  RecommendationOptions.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 12/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

public struct RecommendationOptions: RequestParametersType {
    let id: String
    let fillWithRandom: Bool
    let size: Int
    let items: [String: String]?
    let noTrack: Bool
    let catalogAttributesWhitelist: [String]?

    public init(
        id: String,
        fillWithRandom: Bool,
        size: Int = 10,
        items: [String: String]? = nil,
        noTrack: Bool = false,
        catalogAttributesWhitelist: [String]? = nil
    ) {
        self.id = id
        self.fillWithRandom = fillWithRandom
        self.size = size
        self.items = items
        self.noTrack = noTrack
        self.catalogAttributesWhitelist = catalogAttributesWhitelist
    }

    var parameters: [String: JSONValue] {
        var data: [String: JSONValue] = [
            "type": .string("recommendation"),
            "id": .string(id),
            "fillWithRandom": .bool(fillWithRandom),
            "size": .int(size),
            "no_track": .bool(noTrack)
        ]
        if let items = items {
            data["items"] = .dictionary(items.mapValues { .string($0) })
        }
        if let catalogAttributesWhitelist = catalogAttributesWhitelist {
            data["catalogAttributesWhitelist"] = .array(catalogAttributesWhitelist.map { .string($0) })
        }
        return data
    }
}
