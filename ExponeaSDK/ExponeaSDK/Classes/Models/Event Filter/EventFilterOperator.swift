//
//  EventFilterOperator.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 06/02/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

public protocol EventFilterOperator: Encodable {
    static var name: String { get }
    static var operandCount: Int { get }

    static func passes(
        event: EventFilterEvent,
        attribute: EventFilterAttribute,
        operands: [EventFilterOperand]
    ) -> Bool
}

public struct EventFilterOperand: Codable, Equatable, Sendable {
    var type: String = "constant"
    let value: String
}
