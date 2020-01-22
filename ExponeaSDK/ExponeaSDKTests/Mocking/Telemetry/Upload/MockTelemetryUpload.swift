//
//  MockTelemetryUpload.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 18/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//
@testable import ExponeaSDK

final class MockTelemetryUpload: TelemetryUpload {
    struct UploadedEvent {
        let name: String
        let properties: [String: String]
    }

    // all logs we try to upload
    var uploadedCrashLogs: [CrashLog] = []

    var uploadedEvents: [UploadedEvent] = []

    // settable result for operations
    var result: Bool = true

    func upload(crashLog: CrashLog, completionHandler: (Bool) -> Void) {
        uploadedCrashLogs.append(crashLog)
        completionHandler(result)
    }

    func upload(
        eventWithName name: String,
        properties: [String: String],
        completionHandler: @escaping (Bool) -> Void
    ) {
        uploadedEvents.append(UploadedEvent(name: name, properties: properties))
        completionHandler(result)
    }
}
