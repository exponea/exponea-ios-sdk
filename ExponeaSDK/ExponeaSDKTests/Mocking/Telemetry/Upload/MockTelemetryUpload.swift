//
//  MockTelemetryUpload.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 18/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//
@testable import ExponeaSDK

final class MockTelemetryUpload: TelemetryUpload {
    // all logs we try to upload
    var uploadedCrashLogs: [CrashLog] = []

    // settable result for operations
    var result: Bool = true

    func upload(crashLog: CrashLog, completionHandler: (Bool) -> Void) {
        uploadedCrashLogs.append(crashLog)
        completionHandler(result)
    }
}
