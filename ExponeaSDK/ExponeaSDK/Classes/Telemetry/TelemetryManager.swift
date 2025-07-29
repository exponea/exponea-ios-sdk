//
//  TelemetryManager.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 15/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation
#if canImport(ExponeaSDKShared)
import ExponeaSDKShared
#endif

final class TelemetryManager {
    let storage: TelemetryStorage
    let upload: TelemetryUpload
    let crashManager: CrashManager
    let userDefaults: UserDefaults

    private let runId = UUID().uuidString

    init(
        appGroup: String?,
        userId: String?,
        storage: TelemetryStorage? = nil,
        upload: TelemetryUpload? = nil
    ) {
        self.userDefaults = TelemetryUtility.getUserDefaults(appGroup: appGroup)
        let installId = TelemetryUtility.getInstallId(userDefaults: userDefaults)
        self.storage = storage ?? FileTelemetryStorage()
        self.upload = upload ?? SentryTelemetryUpload(installId: installId) {
            Exponea.shared.configuration
        }
        crashManager = CrashManager(storage: self.storage, upload: self.upload, launchDate: Date(), runId: runId)
    }

    func report(exception: NSException, thread: ThreadInfo) {
        crashManager.caughtExceptionHandler(exception, thread: thread)
    }

    func report(error: Error, stackTrace: [String], thread: ThreadInfo) {
        crashManager.caughtErrorHandler(error, stackTrace: stackTrace, thread: thread)
    }

    func report(eventWithType type: TelemetryEventType, properties: [String: String]) {
        upload.upload(eventLog: EventLog(
            name: type.rawValue,
            runId: runId,
            properties: properties
        )) { result in
            if !result {
                Exponea.logger.log(.error, message: "Uploading telemetry event failed.")
            }
        }
    }

    func report(initEventWithConfiguration configuration: Configuration) {
        report(eventWithType: .sdkConfigure, properties: TelemetryUtility.formatConfigurationForTracking(configuration))
    }

    func start() {
        crashManager.start()
        uploadStoredEvents()
    }

    private func uploadStoredEvents() {
        let events = TelemetryUtility.readTelemetryEvents(self.userDefaults)
        if events.isEmpty {
            return
        }
        Exponea.logger.log(.verbose, message: "Re-uploading of \(events.count) telemetry events starts")
        let group = DispatchGroup()
        events.forEach { each in
            group.enter()
            self.upload.upload(eventLog: each) { _ in
                group.leave()
            }
        }
        group.notify(queue: DispatchQueue.global(qos: .background)) {
            Exponea.logger.log(.verbose, message: "Re-uploading of \(events.count) telemetry events is done")
            TelemetryUtility.saveTelemetryEvents(self.userDefaults, [])
        }
    }
    
    func clear(_ appGroup: String?) {
        let userDefaults = TelemetryUtility.getUserDefaults(appGroup: appGroup)
        TelemetryUtility.saveTelemetryEvents(userDefaults, [])
    }
}
