//
//  RegExpExtensions.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 12/07/2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation

extension NSRegularExpression {
    func matches(in string: String) -> [NSTextCheckingResult] {
        return self.matches(in: string, range: NSRange(
            string.startIndex..<string.endIndex,
            in: string
        ))
    }

    func matchesAsStrings(in string: String) -> [String] {
        return self
            .matches(in: string)
            .flatMap { $0.rangesAsStrings(in: string) }
    }

    func groupsAsStrings(in string: String) -> [String] {
        return self
            .matches(in: string)
            .flatMap { $0.groupsAsStrings(in: string) }
    }
}

extension NSTextCheckingResult {
    func ranges() -> [NSRange] {
        var target: [NSRange] = []
        for index in 0..<self.numberOfRanges {
            target.append(self.range(at: index))
        }
        return target
    }

    func ranges(in source: String) -> [Range<String.Index>] {
        var target: [Range<String.Index>] = []
        for index in 0..<self.numberOfRanges {
            guard let stringRange = Range(self.range(at: index), in: source) else {
                continue
            }
            target.append(stringRange)
        }
        return target
    }

    func rangesAsStrings(in source: String) -> [String] {
        var target: [String] = []
        for range in self.ranges(in: source) {
            target.append(String(source[range]))
        }
        return target
    }

    func groupsAsStrings(in source: String) -> [String] {
        var target: [String] = []
        for range in self.ranges(in: source).dropFirst() {
            target.append(String(source[range]))
        }
        return target
    }

    func rangeAsString(withName name: String, from source: String) -> String? {
        guard let namedRange = Range(self.range(withName: name), in: source) else {
            return nil
        }
        return String(source[namedRange])
    }
}
