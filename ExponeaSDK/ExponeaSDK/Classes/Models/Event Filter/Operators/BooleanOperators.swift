//
//  BooleanOperators.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 06/02/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation

struct IsOperator: EventFilterOperator {
    static let name: String = "is"
    static let operandCount: Int = 1

    static func passes(
        event: EventFilterEvent,
        attribute: EventFilterAttribute,
        operands: [EventFilterOperand]
    ) -> Bool {
        return attribute.getValue(in: event) == operands[0].value
    }
}
