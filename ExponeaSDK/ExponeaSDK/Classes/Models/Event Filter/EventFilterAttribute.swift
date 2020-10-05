//
//  EventFilterAttribute.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 06/02/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

protocol EventFilterAttribute: Codable {
    var type: String { get }
    func isSet(in event: EventFilterEvent) -> Bool
    func getValue(in event: EventFilterEvent) -> String?
}

struct EventFilterAttributeCoder: Codable, Equatable {
    let attribute: EventFilterAttribute

    init(_ attribute: EventFilterAttribute) {
        self.attribute = attribute
    }

    enum CodingKeys: String, CodingKey {
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: CodingKeys.type)
        switch type {
        case "timestamp": attribute = try TimestampAttribute(from: decoder)
        case "property": attribute = try PropertyAttribute(from: decoder)
        default: throw EventFilterError.decodingError(message: "Unknown attribute type \(type).")
        }
    }

    func encode(to encoder: Encoder) throws {
        if let timestampAttribute = attribute as? TimestampAttribute {
            try timestampAttribute.encode(to: encoder)
        } else if let propertyAttribute = attribute as? PropertyAttribute {
            try propertyAttribute.encode(to: encoder)
        } else {
            throw EventFilterError.encodingError(message: "Unknown attribute type.")
        }
    }

    static func == (lhs: EventFilterAttributeCoder, rhs: EventFilterAttributeCoder) -> Bool {
        if let lhsTimestamp = lhs.attribute as? TimestampAttribute,
           let rhsTimestamp = rhs.attribute as? TimestampAttribute {
            return lhsTimestamp == rhsTimestamp
        }
        if let lhsProperty = lhs.attribute as? PropertyAttribute,
           let rhsProperty = rhs.attribute as? PropertyAttribute {
            return lhsProperty == rhsProperty
        }
        return false
    }
}

struct TimestampAttribute: EventFilterAttribute, Codable, Equatable {
    var type: String = "timestamp"

    func isSet(in event: EventFilterEvent) -> Bool {
        return event.timestamp != nil
    }

    func getValue(in event: EventFilterEvent) -> String? {
        if let timestamp = event.timestamp {
            return String(describing: timestamp)
        }
        return nil
    }
}

struct PropertyAttribute: EventFilterAttribute, Codable, Equatable {
    var type: String = "property"
    let property: String

    init(_ property: String) {
        self.property = property
    }

    func isSet(in event: EventFilterEvent) -> Bool {
        return event.properties.contains { $0.key == property }
    }

    func getValue(in event: EventFilterEvent) -> String? {
        if let value = event.properties[property], let unwrappedValue = value {
            return String(describing: unwrappedValue)
        }
        return nil
    }
}
