//
//  Sequence+RemoveInfinity.swift
//  ExponeaSDKShared
//
//  Created by Adam Mihalik on 29/07/2025.
//  Copyright © 2025 Exponea. All rights reserved.
//

import Foundation

public extension Sequence where Self == [String: Any] {
    func removeInfinity() -> [String: Any] {
        var filtered: [String: Any] = [:]
        for dict in self {
            if let array = dict.value as? [Any] {
                filtered[dict.key] = array.removeNill().removeInfinity()
            } else if let array = dict.value as? [Any?] {
                filtered[dict.key] = array.removeNill().removeInfinity()
            } else if let subDic = dict.value as? [String: Any] {
                filtered[dict.key] = subDic.removeNill().removeInfinity()
            } else if let subDic = dict.value as? [String: Any?] {
                filtered[dict.key] = subDic.removeNill().removeInfinity()
            } else if let valueDouble = dict.value as? Double {
                if valueDouble.isNaN || valueDouble.isInfinite {
                    Exponea.logger.log(.verbose, message: "Unable to serialize infinity, skipping")
                } else {
                    filtered[dict.key] = valueDouble
                }
            } else if let valueFloat = dict.value as? Float {
                if valueFloat.isNaN || valueFloat.isInfinite {
                    Exponea.logger.log(.verbose, message: "Unable to serialize infinity, skipping")
                } else {
                    filtered[dict.key] = valueFloat
                }
            } else {
                filtered[dict.key] = dict.value
            }
        }
        return filtered
    }
}

public extension Sequence where Self == [Any] {
    func removeInfinity() -> [Element] {
        var filtered: [Element] = []
        for item in self {
            if let array = item as? [Any] {
                filtered.append(array.removeNill().removeInfinity())
            } else if let array = item as? [Any?] {
                filtered.append(array.removeNill().removeInfinity())
            } else if let dictionary = item as? [String: Any] {
                filtered.append(dictionary.removeNill().removeInfinity())
            } else if let dictionary = item as? [String: Any?] {
                filtered.append(dictionary.removeNill().removeInfinity())
            } else if let valueDouble = item as? Double {
                if valueDouble.isNaN || valueDouble.isInfinite {
                    Exponea.logger.log(.verbose, message: "Unable to serialize infinity, skipping")
                } else {
                    filtered.append(valueDouble)
                }
            } else if let valueFloat = item as? Float {
                if valueFloat.isNaN || valueFloat.isInfinite {
                    Exponea.logger.log(.verbose, message: "Unable to serialize infinity, skipping")
                } else {
                    filtered.append(valueFloat)
                }
            } else {
                filtered.append(item)
            }
        }
        return filtered
    }
}
