//
//  JSONConvertible.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 23/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

public protocol JSONConvertible {
    var jsonValue: JSONValue { get }
}

extension NSString: JSONConvertible {
    public var jsonValue: JSONValue {
        return .string(self as String)
    }
}

extension String: JSONConvertible {
    public var jsonValue: JSONValue {
        return .string(self)
    }
}
extension Bool: JSONConvertible {
    public var jsonValue: JSONValue {
        return .bool(self)
    }
}

extension Int: JSONConvertible {
    public var jsonValue: JSONValue {
        return .int(self)
    }
}
extension Double: JSONConvertible {
    public var jsonValue: JSONValue {
        return .double(self)
    }
}

/// --------

/// When Swift 4.2 is released, use the following and remove workarounds.

//extension Dictionary: JSONConvertible where Key == String, Value == JSONConvertible {
//    public var jsonValue: JSONValue {
//        return .dictionary(self.mapValues({ $0.jsonValue }))
//    }
//}


//extension Array: JSONConvertible where Element == JSONConvertible {
//    public var jsonValue: JSONValue {
//        return .array(self.map({ $0.jsonValue }))
//    }
//}

/// --------

extension Dictionary: JSONConvertible where Key == String, Value == JSONValue {
    public var jsonValue: JSONValue {
        return .dictionary(self)
    }
}

extension Array: JSONConvertible where Element == JSONValue {
    public var jsonValue: JSONValue {
        return .array(self)
    }
}

public indirect enum JSONValue {
    case string(String)
    case bool(Bool)
    case int(Int)
    case double(Double)
    case dictionary([String: JSONValue])
    case array([JSONValue])
}

extension JSONValue {
    var rawValue: Any {
        switch self {
        case .string(let string): return string
        case .bool(let bool): return bool
        case .int(let int): return int
        case .double(let double): return double
        case .dictionary(let dictionary): return dictionary.mapValues { $0.rawValue }
        case .array(let array): return array.map { $0.rawValue }
        }
    }
    
    var jsonConvertible: JSONConvertible {
        switch self {
        case .string(let string): return string
        case .bool(let bool): return bool
        case .int(let int): return int
        case .double(let double): return double
        case .dictionary(let dictionary): return dictionary
        case .array(let array): return array
        }
    }
}

extension JSONValue: Codable, Equatable {
    public init(from decoder: Decoder) throws {
        // Can be made prettier, but as a simple example:
        let container = try decoder.singleValueContainer()
        
        do { self = .string(try container.decode(String.self))
        } catch DecodingError.typeMismatch {
            do { self = .int(try container.decode(Int.self))
            } catch DecodingError.typeMismatch {
                do { self = .dictionary(try container.decode([String: JSONValue].self))
                } catch DecodingError.typeMismatch {
                    do { self = .array(try container.decode([JSONValue].self))
                    } catch {
                        do { self = .bool(try container.decode(Bool.self))
                        } catch { self = .double(try container.decode(Double.self))
                        }
                    }
                }
            }
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .int(let int): try container.encode(int)
        case .string(let string): try container.encode(string)
        case .array(let array): try container.encode(array)
        case .bool(let bool): try container.encode(bool)
        case .double(let double): try container.encode(double)
        case .dictionary(let dictionary): try container.encode(dictionary)
        }
    }
    
    public static func == (_ left: JSONValue, _ right: JSONValue) -> Bool {
        switch (left, right) {
        case (.int(let int1), .int(let int2)): return int1 == int2
        case (.bool(let bool1), .bool(let bool2)): return bool1 == bool2
        case (.double(let double1), .double(let double2)): return double1 == double2
        case (.string(let string1), .string(let string2)): return string1 == string2
        case (.array(let array1), .array(let array2)): return array1 == array2
        case (.dictionary(let dict1), .dictionary(let dict2)): return dict1 == dict2
        default: return false
        }
    }
}

extension JSONValue {
    var objectValue: NSObject {
        switch self {
        case .bool(let bool): return NSNumber(value: bool)
        case .int(let int): return NSNumber(value: int)
        case .string(let string): return NSString(string: string)
        case .array(let array): return array.map({ $0.objectValue }) as NSArray
        case .double(let double): return NSNumber(value: double)
        case .dictionary(let dictionary): return dictionary.mapValues({ $0.objectValue }) as NSDictionary
        }
    }
}
