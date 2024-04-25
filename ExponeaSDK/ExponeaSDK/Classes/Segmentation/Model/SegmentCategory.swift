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
    case merchandise(data: [SegmentDTO] = [])
    case content(data: [SegmentDTO] = [])
    case other

    var id: String {
        switch self {
        case .discovery:
            return "discovery_id"
        case .merchandise:
            return "merchandise_id"
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
        case .merchandise:
            return "merchandise"
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
        case "merchandise":
            self = .merchandise(data: data)
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
