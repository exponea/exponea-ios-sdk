//
//  TelemetryStorage.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 15/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

#if canImport(ExponeaSDKShared)
import ExponeaSDKShared
#endif

protocol TelemetryStorage {
    func saveCrashLog(_ log: CrashLog)
    func deleteCrashLog(_ log: CrashLog)
    func getAllCrashLogs() -> [CrashLog]
}
