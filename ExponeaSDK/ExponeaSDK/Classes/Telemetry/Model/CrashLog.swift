//
//  CrashLog.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 15/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

final class CrashLog: Codable, Equatable {
    let id: String
    let isFatal: Bool
    let errorData: ErrorData
    let timestamp: Double
    let launchTimestamp: Double
    let runId: String

    init(exception: NSException, fatal: Bool, launchDate: Date, runId: String) {
        id = UUID().uuidString
        errorData = ErrorData(
            type: exception.name.rawValue,
            message: exception.reason ?? "",
            stackTrace: exception.callStackSymbols
        )
        self.isFatal = fatal
        timestamp = Date().timeIntervalSince1970
        launchTimestamp = launchDate.timeIntervalSince1970
        self.runId = runId
    }

    init(error: Error, stackTrace: [String], fatal: Bool, launchDate: Date, runId: String) {
        id = UUID().uuidString
        errorData = ErrorData(
            type: String(describing: type(of: error)),
            message: error.localizedDescription,
            stackTrace: stackTrace
        )
        self.isFatal = fatal
        timestamp = Date().timeIntervalSince1970
        launchTimestamp = launchDate.timeIntervalSince1970
        self.runId = runId
    }

    static func == (lhs: CrashLog, rhs: CrashLog) -> Bool {
        return lhs.id == rhs.id
            && lhs.isFatal == rhs.isFatal
            && lhs.errorData == rhs.errorData
            && lhs.timestamp == rhs.timestamp
            && lhs.launchTimestamp == rhs.launchTimestamp
    }
}
