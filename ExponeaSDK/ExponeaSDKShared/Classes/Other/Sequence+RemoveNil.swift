//
//  Sequence+RemoveNil.swift
//  ExponeaSDK
//
//  Created by Ankmara on 18.07.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation

public extension Sequence where Self == Dictionary<String, Any> {
    func removeNill() -> [String: Any] {
        var filtered: [String: Any] = [:]
        for dict in self {
            if let array = dict.value as? Array<Any> {
                filtered[dict.key] = array.removeNill()
            } else if let dictionary = dict.value as? [String: Any?] {
                var dictionaryToAdd: [String: Any] = [:]
                for data in dictionary where data.value != nil {
                    dictionaryToAdd[data.key] = data.value
                }
                if !dictionaryToAdd.isEmpty {
                    filtered[dict.key] = dictionaryToAdd
                }
            } else {
                if let optionalValue = dict.value as? Any?, optionalValue != nil {
                    filtered[dict.key] = dict.value
                }
            }
        }
        return filtered
    }
}

public extension Sequence where Element == Any {
    func removeNill() -> [Element] {
        func flatten<S: Sequence, T>(source: S) -> [T] where S.Element == T? {
            source.lazy.filter { $0 != nil }.compactMap { $0 }
        }
        var filtered: [Element] = []
        for (index, input) in self.enumerated() {
            if let array = input as? Array<Any?> {
                filtered.insert(array.compactMap { $0 }, at: index)
            } else if let dictionary = input as? [String: Any?] {
                var dictionaryToAdd: [String: Any] = [:]
                for data in dictionary where data.value != nil {
                    dictionaryToAdd[data.key] = data.value
                }
                if !dictionaryToAdd.isEmpty {
                    filtered.insert(dictionaryToAdd, at: index)
                }
            } else {
                filtered.append(input)
            }
        }
        return flatten(source: filtered)
    }
}
