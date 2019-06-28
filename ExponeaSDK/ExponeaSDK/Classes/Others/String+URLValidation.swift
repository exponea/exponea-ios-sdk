//
//  String+URLValidation.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 28/06/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

extension String {
    var isValidURL: Bool {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        if let match = detector?.firstMatch(in: self, options: [],
                                            range: NSRange(location: 0, length: utf16.count)) {
            // it is a link, if the match covers the whole string
            return match.range.length == utf16.count
        } else {
            return false
        }
    }
}
