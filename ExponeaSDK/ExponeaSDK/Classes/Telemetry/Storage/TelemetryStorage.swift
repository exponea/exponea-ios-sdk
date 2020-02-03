//
//  TelemetryStorage.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 15/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

protocol TelemetryStorage {
    func saveCrashLog(_ log: CrashLog)
    func deleteCrashLog(_ log: CrashLog)
    func getAllCrashLogs() -> [CrashLog]
}
