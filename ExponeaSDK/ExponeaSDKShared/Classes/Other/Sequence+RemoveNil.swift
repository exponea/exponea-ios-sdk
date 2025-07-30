//
//  Sequence+RemoveNil.swift
//  ExponeaSDK
//
//  Created by Ankmara on 18.07.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation

public extension Sequence where Self == [String: Any?] {
    func removeNill() -> [String: Any] {
        return self.compactMapValues { $0 }.removeNill()
    }
}

public extension Sequence where Self == [String: Any] {
    func removeNill() -> [String: Any] {
        var filtered: [String: Any] = [:]
        for dict in self {
            if let array = dict.value as? [Any?] {
                filtered[dict.key] = array.removeNill()
            } else if let array = dict.value as? [Any] {
                filtered[dict.key] = array.removeNill()
            } else if let dictionary = dict.value as? [String: Any?] {
                filtered[dict.key] = dictionary.removeNill()
            } else if let dictionary = dict.value as? [String: Any] {
                filtered[dict.key] = dictionary.removeNill()
            } else {
                if let optionalValue = dict.value as? Any?, optionalValue != nil {
                    filtered[dict.key] = dict.value
                }
            }
        }
        return filtered
    }
}

public extension Sequence where Self == [Any?] {
    func removeNill() -> [Any] {
        return self.compactMap { $0 }.removeNill()
    }
}

public extension Sequence where Self == [Any] {
    func removeNill() -> [Any] {
        func flatten<S: Sequence, T>(source: S) -> [T] where S.Element == T? {
            source.lazy.filter { $0 != nil }.compactMap { $0 }
        }
        var filtered: [Any] = []
        for item in self {
            if let array = item as? [Any?] {
                filtered.append(array.removeNill())
            } else if let array = item as? [Any] {
                filtered.append(array.removeNill())
            } else if let dictionary = item as? [String: Any?] {
                filtered.append(dictionary.removeNill())
            } else if let dictionary = item as? [String: Any] {
                filtered.append(dictionary.removeNill())
            } else {
                filtered.append(item)
            }
        }
        return flatten(source: filtered)
    }
}
