//
//  ErrorData.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 15/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

public final class ErrorData: Codable, Equatable {
    let type: String
    let message: String
    let stackTrace: [ErrorStackTraceElement]

    init(type: String, message: String, stackTrace: [ErrorStackTraceElement]) {
        self.type = type
        self.message = message
        self.stackTrace = stackTrace
    }

    public static func == (lhs: ErrorData, rhs: ErrorData) -> Bool {
        return lhs.type == rhs.type
            && lhs.message == rhs.message
            && lhs.stackTrace == rhs.stackTrace
    }
}
