//
//  TelemetryManager.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 15/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

final class TelemetryManager {
    let storage: TelemetryStorage
    let upload: TelemetryUpload
    let crashManager: CrashManager

    init(
        userDefaults: UserDefaults,
        userId: String?,
        storage: TelemetryStorage? = nil,
        upload: TelemetryUpload? = nil
    ) {
        let installId = TelemetryUtility.getInstallId(userDefaults: userDefaults)
        let runId = UUID().uuidString
        self.storage = storage ?? FileTelemetryStorage()
        self.upload =
            upload ?? VSAppCenterTelemetryUpload(installId: installId, userId: userId ?? installId, runId: runId)
        crashManager = CrashManager(storage: self.storage, upload: self.upload, launchDate: Date(), runId: runId)
    }

    func report(exception: NSException) {
        crashManager.caughtExceptionHandler(exception)
    }

    func report(error: Error, stackTrace: [String]) {
        crashManager.caughtErrorHandler(error, stackTrace: stackTrace)
    }

    func report(eventWithName name: String, properties: [String: String]) {
        upload.upload(eventWithName: name, properties: properties) { result in
            if !result {
                Exponea.logger.log(.error, message: "Uploading telemetry event failed.")
            }
        }
    }

    func report(initEventWithConfiguration configuration: Configuration) {
        var properties: [String: String] = TelemetryUtility.formatConfigurationForTracking(configuration)
        let version = Bundle(for: Exponea.self).infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        properties["sdkVersion"] = version
        report(eventWithName: "init", properties: properties)
    }

    func start() {
        crashManager.start()
    }
}
