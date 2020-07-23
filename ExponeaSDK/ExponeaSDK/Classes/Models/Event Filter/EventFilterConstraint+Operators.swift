//
//  EventFilterConstraint+Operators.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 06/02/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation

extension StringConstraint {
    static let supportedOperators: [EventFilterOperator.Type] = [
        // generic
        IsSetOperator.self,
        IsNotSetOperator.self,
        HasValueOperator.self,
        HasNoValueOperator.self,
        // string
        EqualsOperator.self,
        DoesNotEqualOperator.self,
        InOperator.self,
        NotInOperator.self,
        ContainsOperator.self,
        DoesNotContainOperator.self,
        StartsWithOperator.self,
        EndsWithOperator.self,
        RegexOperator.self
    ]

    static var isSet: StringConstraint {
        return StringConstraint(filterOperator: IsSetOperator.self, operands: [])
    }

    static var isNotSet: StringConstraint {
        return StringConstraint(filterOperator: IsNotSetOperator.self, operands: [])
    }

    static var hasValue: StringConstraint {
        return StringConstraint(filterOperator: HasValueOperator.self, operands: [])
    }

    static var hasNoValue: StringConstraint {
        return StringConstraint(filterOperator: HasNoValueOperator.self, operands: [])
    }

    static func equals(_ other: String) -> StringConstraint {
        return StringConstraint(filterOperator: EqualsOperator.self, operands: [EventFilterOperand(value: other)])
    }

    static func doesNotEqual(_ other: String) -> StringConstraint {
        return StringConstraint(filterOperator: DoesNotEqualOperator.self, operands: [EventFilterOperand(value: other)])
    }

    static func isIn(_ list: [String]) -> StringConstraint {
        return StringConstraint(
            filterOperator: InOperator.self,
            operands: list.map { EventFilterOperand(value: $0 ) }
        )
    }

    static func notIn(_ list: [String]) -> StringConstraint {
        return StringConstraint(
            filterOperator: NotInOperator.self,
            operands: list.map { EventFilterOperand(value: $0 ) }
        )
    }

    static func contains(_ other: String) -> StringConstraint {
        return StringConstraint(filterOperator: ContainsOperator.self, operands: [EventFilterOperand(value: other)])
    }

    static func doesNotContain(_ other: String) -> StringConstraint {
        return StringConstraint(
            filterOperator: DoesNotContainOperator.self,
            operands: [EventFilterOperand(value: other)]
        )
    }

    static func startsWith(_ other: String) -> StringConstraint {
        return StringConstraint(filterOperator: StartsWithOperator.self, operands: [EventFilterOperand(value: other)])
    }

    static func endsWith(_ other: String) -> StringConstraint {
        return StringConstraint(filterOperator: EndsWithOperator.self, operands: [EventFilterOperand(value: other)])
    }

    static func regex(_ other: String) -> StringConstraint {
        return StringConstraint(filterOperator: RegexOperator.self, operands: [EventFilterOperand(value: other)])
    }
}

extension NumberConstraint {
    static let supportedOperators: [EventFilterOperator.Type] = [
        // generic
        IsSetOperator.self,
        IsNotSetOperator.self,
        HasValueOperator.self,
        HasNoValueOperator.self,
        // number
        EqualToOperator.self,
        InBetweenOperator.self,
        NotBetweenOperator.self,
        LessThanOperator.self,
        GreaterThanOperator.self
    ]

    static var isSet: NumberConstraint {
        return NumberConstraint(filterOperator: IsSetOperator.self, operands: [])
    }

    static var isNotSet: NumberConstraint {
        return NumberConstraint(filterOperator: IsNotSetOperator.self, operands: [])
    }

    static var hasValue: NumberConstraint {
        return NumberConstraint(filterOperator: HasValueOperator.self, operands: [])
    }

    static var hasNoValue: NumberConstraint {
        return NumberConstraint(filterOperator: HasNoValueOperator.self, operands: [])
    }

    static func equalTo(_ other: Double) -> NumberConstraint {
        return NumberConstraint(
            filterOperator: EqualToOperator.self,
            operands: [EventFilterOperand(value: String(describing: other))]
        )
    }

    static func inBetween(_ start: Double, _ end: Double) -> NumberConstraint {
        return NumberConstraint(
            filterOperator: InBetweenOperator.self,
            operands: [
                EventFilterOperand(value: String(describing: start)),
                EventFilterOperand(value: String(describing: end))
            ]
        )
    }

    static func notBetween(_ start: Double, _ end: Double) -> NumberConstraint {
        return NumberConstraint(
            filterOperator: NotBetweenOperator.self,
            operands: [
                EventFilterOperand(value: String(describing: start)),
                EventFilterOperand(value: String(describing: end))
            ]
        )
    }

    static func lessThan(_ other: Double) -> NumberConstraint {
        return NumberConstraint(
            filterOperator: LessThanOperator.self,
            operands: [EventFilterOperand(value: String(describing: other))]
        )
    }

    static func greaterThan(_ other: Double) -> NumberConstraint {
        return NumberConstraint(
            filterOperator: GreaterThanOperator.self,
            operands: [EventFilterOperand(value: String(describing: other))]
        )
    }
}

extension BooleanConstraint {
    static let supportedOperators: [EventFilterOperator.Type] = [
        // generic
        IsSetOperator.self,
        IsNotSetOperator.self,
        HasValueOperator.self,
        HasNoValueOperator.self,
        // boolean
        IsOperator.self
    ]

    static var isSet: BooleanConstraint {
        return BooleanConstraint(filterOperator: IsSetOperator.self, value: true)
    }

    static var isNotSet: BooleanConstraint {
        return BooleanConstraint(filterOperator: IsNotSetOperator.self, value: true)
    }

    static var hasValue: BooleanConstraint {
        return BooleanConstraint(filterOperator: HasValueOperator.self, value: true)
    }

    static var hasNoValue: BooleanConstraint {
        return BooleanConstraint(filterOperator: HasNoValueOperator.self, value: true)
    }

    static func itIs(_ other: Bool) -> BooleanConstraint {
        return BooleanConstraint(filterOperator: IsOperator.self, value: other)
    }
}
