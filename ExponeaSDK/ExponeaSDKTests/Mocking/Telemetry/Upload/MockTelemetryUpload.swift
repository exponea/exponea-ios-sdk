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
    var uploadedCrashLogs: [CrashLog] = []

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
        uploadedCrashLogs.removeAll()
        uploadedSessionRuns.removeAll()
        uploadedEnvelopes.removeAll()
    }
  
    override func upload(eventLog: ExponeaSDKShared.EventLog, completionHandler: @escaping (Bool) -> Void) {
        // Custom events logging disabled - only crash logs and errors are sent to Sentry
        completionHandler(true)
    }

    override func uploadSessionStart(runId: String, completionHandler: @escaping (Bool) -> Void) {
        uploadedSessionRuns.append(runId)
        uploadedEnvelopes.append(buildEnvelope(sessionId: runId))
        completionHandler(result)
    }
}
