//
//  SegmentDTO.swift
//  ExponeaSDK
//
//  Created by Ankmara on 19.04.2024.
//  Copyright © 2024 Exponea. All rights reserved.
//

import Foundation

public struct SegmentStore {
    let customerIds: [String: String]
    let segmentData: SegmentDataDTO

    var toBase64Json: String? {
        var segmentsData: [String: Any] = [:]
        segmentsData["customerIds"] = customerIds
        var categories: [String: Any] = [:]
        for category in segmentData.categories {
            var dataKey: [Any] = []
            switch category {
            case let .discovery(data),
                let .merchandising(data),
                let .content(data):
                data.forEach { segment in
                    var categoryData: [String: String] = [:]
                    categoryData["id"] = segment.id
                    categoryData["segmentation_id"] = segment.segmentationId
                    dataKey.append(categoryData)
                }
                categories[category.name] = dataKey
            case .other: continue
            }
        }
        segmentsData["data"] = categories
        return try? JSONSerialization.data(withJSONObject: segmentsData).base64EncodedString()
    }

    init(customerIds: [String: String], segmentData: SegmentDataDTO) {
        self.customerIds = customerIds
        self.segmentData = segmentData
    }

    init?(data: String?) {
        guard let data = data, let base = Data(base64Encoded: data),
            let json = try? JSONSerialization.jsonObject(with: base) as? [String: Any],
            let dataObject = json["data"] as? [String: Any],
            let dataJson = try? JSONSerialization.data(withJSONObject: dataObject),
            let segment = try? JSONDecoder().decode(SegmentDataDTO.self, from: dataJson)
        else { return nil }
        customerIds = json["customerIds"] as! [String: String]
        segmentData = segment
    }
}

public struct SegmentDataDTO: Codable {

    public var categories: [SegmentCategory]

    public enum CodingKeys: String, CodingKey {
        case categories
    }

    init(categories: [SegmentCategory]) {
        self.categories = categories
    }

    public init(from decoder: any Decoder) throws {
        categories = []
        if let category = try? decoder.singleValueContainer().decode([String: [[String: String]]].self) {
            let categories = category
                .compactMap { key, value in
                    let values = value
                        .compactMap { try? JSONEncoder().encode($0) }
                        .compactMap { try? JSONDecoder().decode(SegmentDTO.self, from: $0) }
                    return SegmentCategory(type: key, data: values)
                }
            self.categories = categories
        }
    }
}

public struct SegmentDTO: Hashable, Codable {
    public let id: String
    public let segmentationId: String

    public enum CodingKeys: String, CodingKey {
        case id
        case segmentationId = "segmentation_id"
    }
}
