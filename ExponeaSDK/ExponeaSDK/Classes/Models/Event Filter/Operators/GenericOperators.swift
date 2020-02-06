//
//  GenericOperators.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 06/02/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation

struct IsSetOperator: EventFilterOperator {
    static let name: String = "is set"
    static let operandCount: Int = 0

    static func passes(
        event: EventFilterEvent,
        attribute: EventFilterAttribute,
        operands: [EventFilterOperand]
    ) -> Bool {
        return attribute.isSet(in: event)
    }
}

struct IsNotSetOperator: EventFilterOperator {
    static let name: String = "is not set"
    static let operandCount: Int = 0

    static func passes(
        event: EventFilterEvent,
        attribute: EventFilterAttribute,
        operands: [EventFilterOperand]
    ) -> Bool {
        return !attribute.isSet(in: event)
    }
}

struct HasValueOperator: EventFilterOperator {
    static let name: String = "has value"
    static let operandCount: Int = 0

    static func passes(
        event: EventFilterEvent,
        attribute: EventFilterAttribute,
        operands: [EventFilterOperand]
    ) -> Bool {
        return attribute.getValue(in: event) != nil
    }
}

struct HasNoValueOperator: EventFilterOperator {
    static let name: String = "has no value"
    static let operandCount: Int = 0

    static func passes(
        event: EventFilterEvent,
        attribute: EventFilterAttribute,
        operands: [EventFilterOperand]
    ) -> Bool {
        return attribute.isSet(in: event) && attribute.getValue(in: event) == nil
    }
}
