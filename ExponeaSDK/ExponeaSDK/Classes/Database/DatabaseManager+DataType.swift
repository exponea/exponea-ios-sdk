//
//  DatabaseManager+DataType.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 02/07/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

extension DatabaseManager {
    static func processProperty(key aKey: String?, value: NSObject?, into dictionary: inout [String: JSONValue]) {
        guard let key = aKey, let value = value else {
            Exponea.logger.log(.verbose, message: "Skipping empty value for property: \(aKey ?? "NO KEY")")
            return
        }
        
        // Check for arrays, we only allow 1 sub-level
        if let array = value as? [NSObject] {
            let converted = array.map({ transformPrimitiveType($0) })
            dictionary[key] = .array(converted.compactMap({ $0 }))
        } else {
            // Otherwise assume a primitive type
            dictionary[key] = transformPrimitiveType(value)
        }
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
            }
            
        default:
            Exponea.logger.log(.warning, message: "Skipping unsupported property value: \(object).")
            return nil
        }
    }
}
