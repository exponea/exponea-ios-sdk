//
//  InAppContentBlockResponse.swift
//  ExponeaSDK
//
//  Created by Ankmara on 26.05.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation

@propertyWrapper
public struct CodableIgnored<T>: Codable {
    public var wrappedValue: T?

    public init(wrappedValue: T?) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        wrappedValue = nil
    }

    public func encode(to encoder: Encoder) throws {}
}

extension KeyedDecodingContainer {
    public func decode<T>(
        _ type: CodableIgnored<T>.Type,
        forKey key: Key) throws -> CodableIgnored<T>
    {
        CodableIgnored(wrappedValue: nil)
    }
}

extension KeyedEncodingContainer {
    public mutating func encode<T>(
        _ value: CodableIgnored<T>,
        forKey key: KeyedEncodingContainer<K>.Key) throws
    {}
}

public struct InAppContentBlocksDataResponse: Codable {
    let data: [InAppContentBlockResponse]
    let success: Bool

    enum CodingKeys: String, CodingKey {
        case data = "in_app_content_blocks"
        case success
    }
}

public struct InAppContentBlockResponse: Codable {

    public struct DateFilter: Codable {
        let enabled: Bool
        let fromDate: UInt?
        let toDate: UInt?

        enum CodingKeys: String, CodingKey {
            case enabled
            case fromDate = "from_date"
            case toDate = "to_date"
        }
    }

    public let id: String
    public let name: String
    public let dateFilter: DateFilter
    @CodableIgnored
    public var frequency: InAppContentBlocksFrequency?
    public var loadPriority: Int? = 0
    public var contentType: InAppContentBlockContentType?
    public var content: Content?
    @CodableIgnored
    public var normalizedResult: NormalizedResult?
    public var trackingConsentCategory: String?
    public let placeholders: [String]
    @CodableIgnored
    public var personalizedMessage: PersonalizedInAppContentBlockResponse?
    @CodableIgnored
    public var status: InAppContentBlocksDisplayStatus?
    @CodableIgnored
    public var sessionStart: Date? = Date()
    @CodableIgnored
    public var tags: Set<Int>? = []
    @CodableIgnored
    public var indexPath: IndexPath?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case dateFilter = "date_filter"
        case loadPriority = "load_priority"
        case contentType = "content_type"
        case content
        case trackingConsentCategory = "consent_category_tracking"
        case placeholders
        case frequency
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.dateFilter = try container.decode(InAppContentBlockResponse.DateFilter.self, forKey: .dateFilter)
        self.loadPriority = try container.decodeIfPresent(Int.self, forKey: .loadPriority)
        self.contentType = try container.decodeIfPresent(InAppContentBlockContentType.self, forKey: .contentType)
        self.content = try container.decodeIfPresent(Content.self, forKey: .content)
        self.trackingConsentCategory = try container.decodeIfPresent(String.self, forKey: .trackingConsentCategory)
        self.placeholders = try container.decode([String].self, forKey: .placeholders)
        let frequency = try container.decode(String.self, forKey: .frequency)
        self.frequency = .init(value: frequency)
    }

    public init(
        id: String,
        name: String,
        dateFilter: DateFilter,
        frequency: InAppContentBlocksFrequency,
        placeholders: [String],
        tags: Set<Int>,
        loadPriority: Int,
        content: Content?,
        personalized: PersonalizedInAppContentBlockResponse?
    ) {
        self.id = id
        self.name = name
        self.dateFilter = dateFilter
        self.frequency = frequency
        self.placeholders = placeholders
        self.tags = tags
        self.loadPriority = loadPriority
        self.content = content
        self.personalizedMessage = personalized
    }
}

public enum InAppContentBlocksFrequency: String {
    case always = "always"
    case onlyOnce = "only_once"
    case oncePerVisit = "once_per_visit"
    case untilVisitorInteracts = "until_visitor_interacts"

    init(value: String) {
        self = .init(rawValue: value) ?? .always
    }
}

public struct InAppContentBlocksDisplayStatus: Codable, Equatable {
    let displayed: Date?
    let interacted: Date?
}
