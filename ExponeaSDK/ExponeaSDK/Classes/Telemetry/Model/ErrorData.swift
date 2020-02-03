//
//  ErrorData.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 15/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

final class ErrorData: Codable, Equatable {
    let type: String
    let message: String
    let stackTrace: [String]

    init(type: String, message: String, stackTrace: [String]) {
        self.type = type
        self.message = message
        self.stackTrace = stackTrace
    }

    static func == (lhs: ErrorData, rhs: ErrorData) -> Bool {
        return lhs.type == rhs.type
            && lhs.message == rhs.message
            && lhs.stackTrace == rhs.stackTrace
    }
}
