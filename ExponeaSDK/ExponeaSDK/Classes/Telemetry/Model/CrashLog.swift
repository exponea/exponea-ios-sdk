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
    let logs: [String]

    init(
        exception: NSException,
        fatal: Bool,
        date: Date,
        launchDate: Date,
        runId: String,
        logs: [String] = []
    ) {
        id = UUID().uuidString
        errorData = ErrorData(
            type: exception.name.rawValue,
            message: exception.reason ?? "",
            stackTrace: exception.callStackSymbols
        )
        self.isFatal = fatal
        timestamp = date.timeIntervalSince1970
        launchTimestamp = launchDate.timeIntervalSince1970
        self.runId = runId
        self.logs = logs
    }

    init(
        error: Error,
        stackTrace: [String],
        fatal: Bool,
        date: Date,
        launchDate: Date,
        runId: String,
        logs: [String] = []
    ) {
        id = UUID().uuidString
        errorData = ErrorData(
            type: String(describing: type(of: error)),
            message: "\((error as NSError).domain):\((error as NSError).code) \(error.localizedDescription)",
            stackTrace: stackTrace
        )
        self.isFatal = fatal
        timestamp = date.timeIntervalSince1970
        launchTimestamp = launchDate.timeIntervalSince1970
        self.runId = runId
        self.logs = logs
    }

    static func == (lhs: CrashLog, rhs: CrashLog) -> Bool {
        return lhs.id == rhs.id
            && lhs.isFatal == rhs.isFatal
            && lhs.errorData == rhs.errorData
            && abs(lhs.timestamp - rhs.timestamp) < 0.0001 // swift has rounding issues
            && abs(lhs.launchTimestamp - rhs.launchTimestamp) < 0.0001
    }
}
