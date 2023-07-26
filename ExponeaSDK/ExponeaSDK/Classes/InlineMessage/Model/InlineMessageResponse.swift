//
//  InlineMessageResponse.swift
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

public struct InlineMessageDataResponse: Codable {
    let data: [InlineMessageResponse]
    let success: Bool
    
    enum CodingKeys: String, CodingKey {
        case data = "inline_messages"
        case success
    }
}

public struct InlineMessageResponse: Codable {

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
    public var frequency: InlineMessageFrequency?
    public var loadPriority: Int? = 0
    public var contentType: InlineMessageContentType?
    public var content: Content?
    public var trackingConsentCategory: String?
    public let placeholders: [String]
    @CodableIgnored
    public var displayState: InlineMessageDisplayStatus? = .init(displayed: nil, interacted: nil)
    @CodableIgnored
    public var personalizedMessage: PersonalizedInlineMessageResponse?
    @CodableIgnored
    public var status: InlineMessageDisplayStatus?
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
        self.dateFilter = try container.decode(InlineMessageResponse.DateFilter.self, forKey: .dateFilter)
        self.loadPriority = try container.decodeIfPresent(Int.self, forKey: .loadPriority)
        self.contentType = try container.decodeIfPresent(InlineMessageContentType.self, forKey: .contentType)
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
        frequency: InlineMessageFrequency,
        placeholders: [String],
        tags: Set<Int>,
        loadPriority: Int,
        content: Content?,
        personalized: PersonalizedInlineMessageResponse?
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

public enum InlineMessageFrequency: String {
    case always = "always"
    case onlyOnce = "only_once"
    case oncePerVisit = "once_per_visit"
    case untilVisitorInteracts = "until_visitor_interacts"
    
    init(value: String) {
        self = .init(rawValue: value) ?? .always
    }
}

public struct InlineMessageDisplayStatus: Codable, Equatable {
    let displayed: Date?
    let interacted: Date?
}
