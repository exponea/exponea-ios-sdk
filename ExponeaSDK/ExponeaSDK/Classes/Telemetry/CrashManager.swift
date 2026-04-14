//
//  CrashManager.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 15/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation
#if canImport(ExponeaSDKShared)
import ExponeaSDKShared
#endif

final class CrashManager {
    // we need to give NSSetUncaughtExceptionHandler a closure that doesn't trap context
    // let's just keep reference to current crash manager, so we can still easily create new ones in tests
    static var current: CrashManager?

    static let logRetention: Double = 60 * 60 * 24 * 15 // 15 days

    let storage: TelemetryStorage
    let upload: TelemetryUpload
    let launchDate: Date
    let runId: String

    private let logsQueue = DispatchQueue(label: "com.exponea.telemetry.crashmanager.logs")
    static let maxLogMessages = 100
    private var logMessages: [String] = []
    private var logHookId: String?
    private var isStarted = false

    var oldHandler: NSUncaughtExceptionHandler?

    init(storage: TelemetryStorage, upload: TelemetryUpload, launchDate: Date, runId: String) {
        self.storage = storage
        self.upload = upload
        self.launchDate = launchDate
        self.runId = runId

        IntegrationManager.shared.onIntegrationStoppedCallbacks.append { [weak self] in
            self?.logMessages.removeAll()
            self?.storage.getAllCrashLogs().forEach({ log in
                self?.storage.deleteCrashLog(log)
            })
        }
    }

    deinit {
        if let hookId = logHookId {
            Exponea.logger.removeLogHook(with: hookId)
        }
    }

    func start() {
        guard !isStarted else { return }
        isStarted = true
        logHookId = Exponea.logger.addLogHook(self.reportLog(_:))
        uploadCrashLogs()
        oldHandler = NSGetUncaughtExceptionHandler()
        CrashManager.current = self
        NSSetUncaughtExceptionHandler({
            CrashManager.current?.uncaughtExceptionHandler($0, thread: TelemetryUtility.getCurrentThreadInfo())
        })
    }

    func uncaughtExceptionHandler(_ exception: NSException, thread: ThreadInfo) {
        self.oldHandler?(exception)
        Exponea.logger.log(.error, message: "Handling uncaught exception")
        if TelemetryUtility.isSDKRelated(stackTrace: exception.callStackSymbols) {
            storage.saveCrashLog(
                CrashLog(
                    exception: exception,
                    fatal: true,
                    date: Date(),
                    launchDate: launchDate,
                    runId: runId,
                    logs: getLogs(),
                    thread: thread
                )
            )
        }
    }

    func caughtExceptionHandler(_ exception: NSException, thread: ThreadInfo) {
        uploadCaughtCrashLog(
            CrashLog(
                exception: exception,
                fatal: false,
                date: Date(),
                launchDate: launchDate,
                runId: runId,
                logs: getLogs(),
                thread: thread
            )
        )
    }

    func caughtErrorHandler(_ error: Error, stackTrace: [String], thread: ThreadInfo) {
        uploadCaughtCrashLog(
            CrashLog(
                error: error,
                stackTrace: stackTrace,
                fatal: false,
                date: Date(),
                launchDate: launchDate,
                runId: runId,
                logs: getLogs(),
                thread: thread
            )
        )
    }

    func uploadCaughtCrashLog(_ crashLog: CrashLog) {
        guard !IntegrationManager.shared.isStopped else {
            Exponea.logger.log(.error, message: "uploadCaughtCrashLog skipped, SDK is stopped")
            return
        }
        upload.upload(crashLog: crashLog) { result in
            if !result {
                Exponea.logger.log(.error, message: "Uploading crash log failed")
                self.storage.saveCrashLog(crashLog)
            }
        }
    }

    func reportLog(_ message: String) {
        logsQueue.sync { [weak self] in
            self?.logMessages.append(message)
            if self?.logMessages.count ?? 0 > CrashManager.maxLogMessages {
                
            }
        }
    }

    func getLogs() -> [String] {
        return logsQueue.sync {
            self.logMessages
        }
    }

    func uploadCrashLogs() {
        guard !IntegrationManager.shared.isStopped else {
            Exponea.logger.log(.error, message: "uploadCrashLogs skipped, SDK is stopped")
            return
        }
        storage.getAllCrashLogs().forEach { crashLog in
            if crashLog.timestamp > Date().timeIntervalSince1970 - CrashManager.logRetention {
                upload.upload(crashLog: crashLog) { result in
                    if result {
                        Exponea.logger.log(.verbose, message: "Successfully uploaded crash log")
                        self.storage.deleteCrashLog(crashLog)
                    } else {
                        Exponea.logger.log(.error, message: "Uploading crash log failed")
                    }
                }
            } else {
                self.storage.deleteCrashLog(crashLog)
            }
        }
    }
}
