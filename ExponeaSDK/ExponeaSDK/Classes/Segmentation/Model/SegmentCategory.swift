//
//  SegmentCategory.swift
//  ExponeaSDK
//
//  Created by Ankmara on 19.04.2024.
//  Copyright © 2024 Exponea. All rights reserved.
//

import Foundation

public enum SegmentCategory: Hashable, Codable {

    case discovery(data: [SegmentDTO] = [])
    case merchandising(data: [SegmentDTO] = [])
    case content(data: [SegmentDTO] = [])
    case other

    var id: String {
        switch self {
        case .discovery:
            return "discovery_id"
        case .merchandising:
            return "merchandising_id"
        case .other:
            return "other_id"
        case .content:
            return "content_id"
        }
    }

    var name: String {
        switch self {
        case .discovery:
            return "discovery"
        case .merchandising:
            return "merchandising"
        case .other:
            return "other"
        case .content:
            return "content"
        }
    }

    public init(type: String, data: [SegmentDTO]) {
        switch type.lowercased() {
        case "discovery":
            self = .discovery(data: data)
        case "merchandising":
            self = .merchandising(data: data)
        case "content":
            self = .content(data: data)
        default:
            self = .other
        }
    }

    public static func == (lhs: SegmentCategory, rhs: SegmentCategory) -> Bool {
        lhs.id == rhs.id
    }
}
