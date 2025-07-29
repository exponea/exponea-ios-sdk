//
//  MockTelemetryUpload.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 18/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//
@testable import ExponeaSDK
@testable import ExponeaSDKShared

final class MockTelemetryUpload: SentryTelemetryUpload {
    struct UploadedEvent {
        let name: String
        let properties: [String: String]
    }

    // all logs we try to upload
    var uploadedCrashLogs: [CrashLog] = []

    var uploadedEvents: [UploadedEvent] = []

    var uploadedSessionRuns: [String] = []
    
    var uploadedEnvelopes: [Any] = []

    // settable result for operations
    var result: Bool = true

    override func upload(crashLog: CrashLog, completionHandler: @escaping (Bool) -> Void) {
        uploadedCrashLogs.append(crashLog)
        uploadedEnvelopes.append(buildEnvelope(crashLog: crashLog))
        completionHandler(result)
    }

    func removeAll() {
        uploadedEvents.removeAll()
        uploadedCrashLogs.removeAll()
        uploadedSessionRuns.removeAll()
        uploadedEnvelopes.removeAll()
    }

    override func upload(eventLog: ExponeaSDKShared.EventLog, completionHandler: @escaping (Bool) -> Void) {
        guard !IntegrationManager.shared.isStopped else {
            return
        }
        uploadedEvents.append(UploadedEvent(name: eventLog.name, properties: eventLog.properties))
        uploadedEnvelopes.append(buildEnvelope(eventLog: eventLog))
        completionHandler(result)
    }

    override func uploadSessionStart(runId: String, completionHandler: @escaping (Bool) -> Void) {
        uploadedSessionRuns.append(runId)
        uploadedEnvelopes.append(buildEnvelope(sessionId: runId))
        completionHandler(result)
    }
}
