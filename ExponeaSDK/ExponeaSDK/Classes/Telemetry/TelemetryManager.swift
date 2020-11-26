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

    func report(eventWithType type: TelemetryEventType, properties: [String: String]) {
        let appInfo = TelemetryUtility.appInfo
        var allProperties = [
            "sdkVersion": Exponea.version,
            "appName": appInfo.appName,
            "appVersion": appInfo.appVersion,
            "appNameVersion": "\(appInfo.appName) - \(appInfo.appVersion)",
            "appNameVersionSdkVersion":
                "\(appInfo.appName) - \(appInfo.appVersion) - SDK \(Exponea.version)"
        ]
        allProperties.merge(properties, uniquingKeysWith: { first, _ in return first })
        upload.upload(eventWithName: type.rawValue, properties: allProperties) { result in
            if !result {
                Exponea.logger.log(.error, message: "Uploading telemetry event failed.")
            }
        }
    }

    func report(initEventWithConfiguration configuration: Configuration) {
        report(eventWithType: .initialize, properties: TelemetryUtility.formatConfigurationForTracking(configuration))
    }

    func start() {
        crashManager.start()
    }
}
