//
//  NumberOperators.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 06/02/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation

struct EqualToOperator: EventFilterOperator {
    static let name: String = "equal to"
    static let operandCount: Int = 1

    static func passes(
        event: EventFilterEvent,
        attribute: EventFilterAttribute,
        operands: [EventFilterOperand]
    ) -> Bool {
        guard let value = attribute.getValue(in: event) else { return false }
        return Double(value) == Double(operands[0].value)
    }
}

struct InBetweenOperator: EventFilterOperator {
    static let name: String = "in between"
    static let operandCount: Int = 2

    static func passes(
        event: EventFilterEvent,
        attribute: EventFilterAttribute,
        operands: [EventFilterOperand]
    ) -> Bool {
        guard let value = attribute.getValue(in: event),
              let numberValue = Double(value),
              let start = Double(operands[0].value),
              let end = Double(operands[1].value) else {
            return false
        }
        return start <= numberValue && numberValue <= end
    }
}

struct NotBetweenOperator: EventFilterOperator {
    static let name: String = "not between"
    static let operandCount: Int = 2

    static func passes(
        event: EventFilterEvent,
        attribute: EventFilterAttribute,
        operands: [EventFilterOperand]
    ) -> Bool {
        guard let value = attribute.getValue(in: event),
              let numberValue = Double(value),
              let start = Double(operands[0].value),
              let end = Double(operands[1].value) else {
            return false
        }
        return start > numberValue || numberValue > end
    }
}

struct LessThanOperator: EventFilterOperator {
    static let name: String = "less than"
    static let operandCount: Int = 1

    static func passes(
        event: EventFilterEvent,
        attribute: EventFilterAttribute,
        operands: [EventFilterOperand]
    ) -> Bool {
        guard let value = attribute.getValue(in: event),
              let numberValue = Double(value),
              let numberOperand = Double(operands[0].value) else {
                return false
        }
        return numberValue < numberOperand
    }
}

struct GreaterThanOperator: EventFilterOperator {
    static let name: String = "greater than"
    static let operandCount: Int = 1

    static func passes(
        event: EventFilterEvent,
        attribute: EventFilterAttribute,
        operands: [EventFilterOperand]
    ) -> Bool {
        guard let value = attribute.getValue(in: event),
              let numberValue = Double(value),
              let numberOperand = Double(operands[0].value) else {
                return false
        }
        return numberValue > numberOperand
    }
}
