//
//  CrashLog.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 15/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

public final class CrashLog: Codable, Equatable {
    public let id: String
    public let isFatal: Bool
    public let errorData: ErrorData
    public let timestamp: Double
    public let launchTimestamp: Double
    public let runId: String
    public let logs: [String]
    public let thread: ThreadInfo

    public init(
        exception: NSException,
        fatal: Bool,
        date: Date,
        launchDate: Date,
        runId: String,
        logs: [String] = [],
        thread: ThreadInfo
    ) {
        id = UUID().uuidString
        errorData = ErrorData(
            type: exception.name.rawValue,
            message: exception.reason ?? "",
            stackTrace: TelemetryUtility.readStackTraceInfo(exception)
        )
        self.isFatal = fatal
        timestamp = date.timeIntervalSince1970
        launchTimestamp = launchDate.timeIntervalSince1970
        self.runId = runId
        self.logs = logs
        self.thread = TelemetryUtility.updateThreadInfo(from: thread, with: exception.callStackSymbols)
    }

    public init(
        error: Error,
        stackTrace: [String],
        fatal: Bool,
        date: Date,
        launchDate: Date,
        runId: String,
        logs: [String] = [],
        thread: ThreadInfo
    ) {
        id = UUID().uuidString
        let nsError = (error as NSError)
        errorData = ErrorData(
            type: String(describing: type(of: error)),
            message: "\(nsError.domain):\(nsError.code) \(error.localizedDescription)",
            stackTrace: TelemetryUtility.parseStackTrace(stackTrace)
        )
        self.isFatal = fatal
        timestamp = date.timeIntervalSince1970
        launchTimestamp = launchDate.timeIntervalSince1970
        self.runId = runId
        self.logs = logs
        self.thread = TelemetryUtility.updateThreadInfo(from: thread, with: stackTrace)
    }

    public static func == (lhs: CrashLog, rhs: CrashLog) -> Bool {
        return lhs.id == rhs.id
            && lhs.isFatal == rhs.isFatal
            && lhs.errorData == rhs.errorData
            && abs(lhs.timestamp - rhs.timestamp) < 0.0001 // swift has rounding issues
            && abs(lhs.launchTimestamp - rhs.launchTimestamp) < 0.0001
    }
}
