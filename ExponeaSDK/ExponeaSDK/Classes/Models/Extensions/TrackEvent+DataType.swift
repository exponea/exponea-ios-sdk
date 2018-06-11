//
//  TrackEvent+DataType.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 11/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

extension TrackEvent {
    var dataTypes: [DataType] {
        var data: [DataType] = []
        
        // Add project token.
        if let token = projectToken {
            data.append(.projectToken(token))
        }
        
        // Convert all properties to key value items.
        if let properties = trackEventProperties as? Set<TrackEventProperty> {
            var props: [String: JSONValue] = [:]
            properties.forEach({
                DatabaseManager.processProperty(key: $0.key,
                                                value: $0.value,
                                                into: &props)
            })
            data.append(.properties(props))
        }
        
        // Add event type.
        if let eventType = eventType {
            data.append(.eventType(eventType))
        }
        
        // Add timestamp if we have it, otherwise none.
        data.append(.timestamp(timestamp == 0 ? nil : timestamp))
        
        return data
    }
}

extension DatabaseManager {
    static func processProperty(key: String?, value: NSObject?, into dictionary: inout [String: JSONValue]) {
        guard let value = value else {
            Exponea.logger.log(.verbose, message: "Skipping empty value for property: \(key ?? "Empty")")
            return
        }
        
        switch value.self {
        case is NSString:
            guard let string = value as? NSString else {
                Exponea.logger.log(.error, message: "Failed to convert NSObject to NSString for: \(value).")
                break
            }
            dictionary[key!] = .string(string as String)
            
        case is NSNumber:
            guard let number = value as? NSNumber else {
                Exponea.logger.log(.error, message: "Failed to convert NSObject to NSNumber for: \(value).")
                break
            }
            
            // Switch based on number type
            switch CFNumberGetType(number) {
            case .charType:
                dictionary[key!] = .bool(number.boolValue)
            case .sInt8Type, .sInt16Type, .sInt32Type, .sInt64Type, .shortType,
                 .intType, .longType, .longLongType, .cfIndexType, .nsIntegerType:
                dictionary[key!] = .int(number.intValue)
            case .float32Type, .float64Type, .floatType, .doubleType, .cgFloatType:
                dictionary[key!] = .double(number.doubleValue)
            }
            
        default:
            Exponea.logger.log(.verbose, message: "Skipping unsupported property value: \(value).")
            break
        }
    }
}
