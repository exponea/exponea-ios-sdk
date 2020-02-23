//
//  EventFilter.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 05/02/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation

struct EventFilterEvent {
    let eventType: String
    let properties: [String: Any?]
    let timestamp: Double?
}

enum EventFilterError: LocalizedError {
    case encodingError(message: String)
    case decodingError(message: String)
    case incorrectOperandCount(filterOperator: EventFilterOperator.Type, count: Int)

    public var errorDescription: String? {
        switch self {
        case .encodingError(let message): return "Error encoding event filter: \(message)"
        case .decodingError(let message): return "Error decoding event filter: \(message)"
        case .incorrectOperandCount(let filterOperator, let count):
            return """
            Incorrect operand count for operator \(filterOperator.name). \
            Required \(filterOperator.operandCount), got \(count).
            """
        }
    }
}

struct EventFilter: Codable, Equatable {
    internal static let anyOperatorCount: Int = -1

    let eventType: String
    let filter: [EventPropertyFilter]

    func passes(event: EventFilterEvent) throws -> Bool {
        guard event.eventType == eventType else {
            return false
        }
        return try filter.allSatisfy { try $0.passes(event: event) }
    }

    enum CodingKeys: String, CodingKey {
        case eventType = "event_type"
        case filter = "filter"
    }
}

struct EventPropertyFilter: Equatable {
    let attribute: EventFilterAttribute
    let constraint: EventFilterConstraint

    init(attribute: EventFilterAttribute, constraint: EventFilterConstraint) {
        self.attribute = attribute
        self.constraint = constraint
    }

    static func timestamp(_ constraint: EventFilterConstraint) -> EventPropertyFilter {
        return EventPropertyFilter(attribute: TimestampAttribute(), constraint: constraint)
    }

    static func property(_ property: String, _ constraint: EventFilterConstraint) -> EventPropertyFilter {
        return EventPropertyFilter(attribute: PropertyAttribute(property), constraint: constraint)
    }

    func passes(event: EventFilterEvent) throws -> Bool {
        return try constraint.passes(event: event, attribute: attribute)
    }

    static func == (lhs: EventPropertyFilter, rhs: EventPropertyFilter) -> Bool {
        return EventFilterAttributeCoder(lhs.attribute) == EventFilterAttributeCoder(rhs.attribute)
            && EventFilterConstraintCoder(lhs.constraint) == EventFilterConstraintCoder(rhs.constraint)
    }
}

extension EventPropertyFilter: Codable {
    init(from decoder: Decoder) throws {
        let data = try decoder.container(keyedBy: CodingKeys.self)
        attribute = try data.decode(EventFilterAttributeCoder.self, forKey: .attribute).attribute
        constraint = try data.decode(EventFilterConstraintCoder.self, forKey: .constraint).constraint
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(EventFilterAttributeCoder(attribute), forKey: .attribute)
        try container.encode(EventFilterConstraintCoder(constraint), forKey: .constraint)
    }

    enum CodingKeys: String, CodingKey {
        case attribute
        case constraint
    }
}
