//
//  DatabaseManager+DataType.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 02/07/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

extension DatabaseManager {
    static func processObject(_ object: NSObject) -> JSONValue? {
        if let dictionary = object as? NSDictionary {
            return processDictionary(dictionary)
        } else if let array = object as? NSArray {
            return processArray(array)
        } else if let primitiveType = transformPrimitiveType(object) {
            return primitiveType
        }

        Exponea.logger.log(.warning, message: "Skipping object of unsupported type: \(object.self)")
        return nil
    }

    static func processArray(_ array: NSArray) -> JSONValue {
        var valueArray: [JSONValue] = []

        for element in array {
            guard let object = element as? NSObject else {
                Exponea.logger.log(.warning, message: "Skipping array element of unsupported type: \(element.self)")
                continue
            }

            if let nested = object as? NSArray {
                valueArray.append(processArray(nested))
            } else if let primitiveType = transformPrimitiveType(object) {
                valueArray.append(primitiveType)
            } else {
                Exponea.logger.log(.warning, message: "Skipping array element of unsupported type: \(object.self)")
                continue
            }
        }

        return .array(valueArray)
    }

    static func processDictionary(_ dictionary: NSDictionary) -> JSONValue {
        var valueDictionary: [String: JSONValue] = [:]

        for (anyKey, anyValue) in dictionary {
            guard let key = anyKey as? String else {
                Exponea.logger.log(.warning,
                                   message: "Skipping dictionary pair because key is not a string: \(anyKey.self).")
                continue
            }

            guard let value = anyValue as? NSObject else {
                Exponea.logger.log(
                    .warning,
                    message: "Skipping dictionary pair because value is not an object: \(anyValue.self)."
                )
                continue
            }

            if let nested = value as? NSDictionary {
                valueDictionary[key] = processDictionary(nested)
            } else if let nested = value as? NSArray {
                valueDictionary[key] = processArray(nested)
            } else if let primitiveType = transformPrimitiveType(value) {
                valueDictionary[key] = primitiveType
            } else {
                Exponea.logger.log(.warning, message: """
                    Skipping dictionary value (with key \(key)) of unsupported type: \(value.self).
                    """)
                continue
            }
        }

        return .dictionary(valueDictionary)
    }

    static func transformPrimitiveType(_ object: NSObject) -> JSONValue? {
        switch object.self {
        case is NSString:
            guard let string = object as? NSString else {
                Exponea.logger.log(.error, message: "Failed to convert NSObject to NSString for: \(object).")
                return nil
            }
            return .string(string as String)

        case is NSNumber:
            guard let number = object as? NSNumber else {
                Exponea.logger.log(.error, message: "Failed to convert NSObject to NSNumber for: \(object).")
                return nil
            }

            // Switch based on number type
            switch CFNumberGetType(number) {
            case .charType:
                return .bool(number.boolValue)
            case .sInt8Type, .sInt16Type, .sInt32Type, .sInt64Type, .shortType,
                 .intType, .longType, .longLongType, .cfIndexType, .nsIntegerType:
                return .int(number.intValue)
            case .float32Type, .float64Type, .floatType, .doubleType, .cgFloatType:
                return .double(number.doubleValue)
            @unknown default:
                return .bool(number.boolValue)
            }

        default:
            Exponea.logger.log(.warning, message: "Skipping unsupported property value: \(object).")
            return nil
        }
    }
}
