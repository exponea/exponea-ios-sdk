//
//  EventFilterConstraint.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 06/02/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

protocol EventFilterConstraint: Codable {
    var type: String { get }
    var filterOperator: EventFilterOperator.Type { get }

    func passes(event: EventFilterEvent, attribute: EventFilterAttribute) throws -> Bool
}

struct EventFilterConstraintCoder: Codable, Equatable {
    let constraint: EventFilterConstraint

    init(_ constraint: EventFilterConstraint) {
        self.constraint = constraint
    }

    enum CodingKeys: String, CodingKey {
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: CodingKeys.type)
        switch type {
        case "string": constraint = try StringConstraint(from: decoder)
        case "number": constraint = try NumberConstraint(from: decoder)
        case "boolean": constraint = try BooleanConstraint(from: decoder)
        default: throw EventFilterError.decodingError(message: "Unknown constraint type \(type).")
        }
    }

    func encode(to encoder: Encoder) throws {
        if let stringConstraint = constraint as? StringConstraint {
            try stringConstraint.encode(to: encoder)
        } else if let numberConstraint = constraint as? NumberConstraint {
            try numberConstraint.encode(to: encoder)
        } else if let booleanConstraint = constraint as? BooleanConstraint {
            try booleanConstraint.encode(to: encoder)
        } else {
            throw EventFilterError.encodingError(message: "Unknown constraint type.")
        }
    }

    static func == (lhs: EventFilterConstraintCoder, rhs: EventFilterConstraintCoder) -> Bool {
        if let lhsString = lhs.constraint as? StringConstraint,
           let rhsString = rhs.constraint as? StringConstraint {
            return lhsString == rhsString
        }
        if let lhsNumber = lhs.constraint as? NumberConstraint,
           let rhsNumber = rhs.constraint as? NumberConstraint {
            return lhsNumber == rhsNumber
        }
        if let lhsBoolean = lhs.constraint as? BooleanConstraint,
           let rhsBoolean = rhs.constraint as? BooleanConstraint {
            return lhsBoolean == rhsBoolean
        }
        return false
    }
}

struct StringConstraint: EventFilterConstraint, Equatable {
    let type: String = "string"
    let filterOperator: EventFilterOperator.Type
    let operands: [EventFilterOperand]

    init(filterOperator: EventFilterOperator.Type, operands: [EventFilterOperand]) {
        self.filterOperator = filterOperator
        self.operands = operands
    }

    func passes(event: EventFilterEvent, attribute: EventFilterAttribute) throws -> Bool {
        guard filterOperator.operandCount == EventFilter.anyOperatorCount
              || operands.count == filterOperator.operandCount else {
            throw EventFilterError.incorrectOperandCount(filterOperator: filterOperator, count: operands.count)
        }
        return filterOperator.passes(event: event, attribute: attribute, operands: operands)
    }

    static func == (lhs: StringConstraint, rhs: StringConstraint) -> Bool {
        return lhs.filterOperator.name == rhs.filterOperator.name && lhs.operands == rhs.operands
    }
}

extension StringConstraint: Codable {
    private static func getOperator(with name: String) throws -> EventFilterOperator.Type {
        guard let filterOperator = StringConstraint.supportedOperators.first(where: { $0.name == name }) else {
            throw EventFilterError.decodingError(message: "Operator \(name) is not supported for string constraint.")
        }
        return filterOperator
    }

    init(from decoder: Decoder) throws {
        let data = try decoder.container(keyedBy: CodingKeys.self)
        operands = try data.decode([EventFilterOperand].self, forKey: .operands)
        let operatorName = try data.decode(String.self, forKey: .filterOperator)
        filterOperator = try StringConstraint.getOperator(with: operatorName)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(filterOperator.name, forKey: .filterOperator)
        try container.encode(operands, forKey: .operands)
    }

    enum CodingKeys: String, CodingKey {
        case type
        case filterOperator = "operator"
        case operands
    }
}

struct NumberConstraint: EventFilterConstraint, Equatable {
    let type: String = "number"
    let filterOperator: EventFilterOperator.Type
    let operands: [EventFilterOperand]

    init(filterOperator: EventFilterOperator.Type, operands: [EventFilterOperand]) {
        self.filterOperator = filterOperator
        self.operands = operands
    }

    func passes(event: EventFilterEvent, attribute: EventFilterAttribute) throws -> Bool {
        guard filterOperator.operandCount == EventFilter.anyOperatorCount
              || operands.count == filterOperator.operandCount else {
            throw EventFilterError.incorrectOperandCount(filterOperator: filterOperator, count: operands.count)
        }
        return filterOperator.passes(event: event, attribute: attribute, operands: operands)
    }

    static func == (lhs: NumberConstraint, rhs: NumberConstraint) -> Bool {
        return lhs.filterOperator.name == rhs.filterOperator.name && lhs.operands == rhs.operands
    }
}

extension NumberConstraint: Codable {
    private static func getOperator(with name: String) throws -> EventFilterOperator.Type {
        guard let filterOperator = NumberConstraint.supportedOperators.first(where: { $0.name == name }) else {
            throw EventFilterError.decodingError(message: "Operator \(name) is not supported for number constraint.")
        }
        return filterOperator
    }

    init(from decoder: Decoder) throws {
        let data = try decoder.container(keyedBy: CodingKeys.self)
        operands = try data.decode([EventFilterOperand].self, forKey: .operands)
        let operatorName = try data.decode(String.self, forKey: .filterOperator)
        filterOperator = try NumberConstraint.getOperator(with: operatorName)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(filterOperator.name, forKey: .filterOperator)
        try container.encode(operands, forKey: .operands)
    }

    enum CodingKeys: String, CodingKey {
        case type
        case filterOperator = "operator"
        case operands
    }
}

struct BooleanConstraint: EventFilterConstraint {
    let type: String = "boolean"
    let filterOperator: EventFilterOperator.Type
    let value: String

    init(filterOperator: EventFilterOperator.Type, value: Bool) {
        self.filterOperator = filterOperator
        self.value = String(describing: value)
    }

    func passes(event: EventFilterEvent, attribute: EventFilterAttribute) throws -> Bool {
        return filterOperator.passes(
            event: event,
            attribute: attribute,
            operands: [EventFilterOperand(value: value)]
        )
    }

    static func == (lhs: BooleanConstraint, rhs: BooleanConstraint) -> Bool {
        return lhs.filterOperator.name == rhs.filterOperator.name && lhs.value == rhs.value
    }
}

extension BooleanConstraint: Codable {
    private static func getOperator(with name: String) throws -> EventFilterOperator.Type {
        guard let filterOperator = BooleanConstraint.supportedOperators.first(where: { $0.name == name }) else {
            throw EventFilterError.decodingError(message: "Operator \(name) is not supported for boolean constraint.")
        }
        return filterOperator
    }

    init(from decoder: Decoder) throws {
        let data = try decoder.container(keyedBy: CodingKeys.self)
        value = try data.decode(String.self, forKey: .value)
        let operatorName = try data.decode(String.self, forKey: .filterOperator)
        filterOperator = try BooleanConstraint.getOperator(with: operatorName)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(filterOperator.name, forKey: .filterOperator)
        try container.encode(value, forKey: .value)
    }

    enum CodingKeys: String, CodingKey {
        case type
        case filterOperator = "operator"
        case value
    }
}
