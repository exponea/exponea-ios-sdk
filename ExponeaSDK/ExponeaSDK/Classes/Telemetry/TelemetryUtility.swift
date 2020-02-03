//
//  TelemetryUtility.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 18/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

final class TelemetryUtility {
    static let telemetryInstallId = "EXPONEA_TELEMETRY_INSTALL_ID"

    static func isSDKRelated(stackTrace: [String]) -> Bool {
        return stackTrace.joined().contains("Exponea") || stackTrace.joined().contains("exponea")
    }

    static func getInstallId(userDefaults: UserDefaults) -> String {
        if let installId = userDefaults.string(forKey: telemetryInstallId) {
            return installId
        }
        let installId = UUID().uuidString
        userDefaults.set(installId, forKey: telemetryInstallId)
        return installId
    }
}
