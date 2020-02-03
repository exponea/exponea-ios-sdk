//
//  MockTelemetryStorage.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 18/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

@testable import ExponeaSDK

final class MockTelemetryStorage: TelemetryStorage {
    private var crashLogs: [CrashLog] = []

    func saveCrashLog(_ log: CrashLog) {
        crashLogs.append(log)
    }

    func deleteCrashLog(_ log: CrashLog) {
        crashLogs = crashLogs.filter { $0.id != log.id }
    }

    func getAllCrashLogs() -> [CrashLog] {
        return crashLogs
    }
}
