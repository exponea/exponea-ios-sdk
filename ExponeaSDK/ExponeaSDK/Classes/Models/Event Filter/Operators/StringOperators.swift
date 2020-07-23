//
//  StringOperators.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 06/02/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation

struct EqualsOperator: EventFilterOperator {
    static let name: String = "equals"
    static let operandCount: Int = 1

    static func passes(
        event: EventFilterEvent,
        attribute: EventFilterAttribute,
        operands: [EventFilterOperand]
    ) -> Bool {
        return attribute.getValue(in: event) == operands[0].value
    }
}

struct DoesNotEqualOperator: EventFilterOperator {
    static let name: String = "does not equal"
    static let operandCount: Int = 1

    static func passes(
        event: EventFilterEvent,
        attribute: EventFilterAttribute,
        operands: [EventFilterOperand]
    ) -> Bool {
        guard let value = attribute.getValue(in: event) else { return false }
        return value != operands[0].value
    }
}

struct InOperator: EventFilterOperator {
    static let name: String = "in"
    static let operandCount: Int = EventFilter.anyOperatorCount

    static func passes(
        event: EventFilterEvent,
        attribute: EventFilterAttribute,
        operands: [EventFilterOperand]
    ) -> Bool {
        return operands.first(where: { $0.value == attribute.getValue(in: event) }) != nil
    }
}

struct NotInOperator: EventFilterOperator {
    static let name: String = "not in"
    static let operandCount: Int = EventFilter.anyOperatorCount

    static func passes(
        event: EventFilterEvent,
        attribute: EventFilterAttribute,
        operands: [EventFilterOperand]
    ) -> Bool {
        guard let value = attribute.getValue(in: event) else { return false }
        return operands.first(where: { $0.value == value }) == nil
    }
}

struct ContainsOperator: EventFilterOperator {
    static let name: String = "contains"
    static let operandCount: Int = 1

    static func passes(
        event: EventFilterEvent,
        attribute: EventFilterAttribute,
        operands: [EventFilterOperand]
    ) -> Bool {
        guard let value = attribute.getValue(in: event) else { return false }
        return value.contains(operands[0].value)
    }
}

struct DoesNotContainOperator: EventFilterOperator {
    static let name: String = "does not contain"
    static let operandCount: Int = 1

    static func passes(
        event: EventFilterEvent,
        attribute: EventFilterAttribute,
        operands: [EventFilterOperand]
    ) -> Bool {
        guard let value = attribute.getValue(in: event) else { return false }
        return !value.contains(operands[0].value)
    }
}

struct StartsWithOperator: EventFilterOperator {
    static let name: String = "starts with"
    static let operandCount: Int = 1

    static func passes(
        event: EventFilterEvent,
        attribute: EventFilterAttribute,
        operands: [EventFilterOperand]
    ) -> Bool {
        guard let value = attribute.getValue(in: event) else { return false }
        return value.hasPrefix(operands[0].value)
    }
}

struct EndsWithOperator: EventFilterOperator {
    static let name: String = "ends with"
    static let operandCount: Int = 1

    static func passes(
        event: EventFilterEvent,
        attribute: EventFilterAttribute,
        operands: [EventFilterOperand]
    ) -> Bool {
        guard let value = attribute.getValue(in: event) else { return false }
        return value.hasSuffix(operands[0].value)
    }
}

struct RegexOperator: EventFilterOperator {
    static let name: String = "regex"
    static let operandCount: Int = 1

    static func passes(
        event: EventFilterEvent,
        attribute: EventFilterAttribute,
        operands: [EventFilterOperand]
    ) -> Bool {
        guard let value = attribute.getValue(in: event) else { return false }
        return value.range(of: operands[0].value, options: .regularExpression) != nil
    }
}
