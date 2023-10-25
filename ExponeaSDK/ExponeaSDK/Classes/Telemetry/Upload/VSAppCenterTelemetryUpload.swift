//
//  VSAppCenterTelemetryUpload.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 18/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import UIKit

final class VSAppCenterTelemetryUpload: TelemetryUpload {
    let defaultUploadURL = "https://in.appcenter.ms/logs?Api-Version=1.0.0"
    let debugAppSecret = "7172e098-ec8e-4d1b-9f9e-3e5107d8b22a"
    let releaseAppSecret = "4d80509d-4d1c-4d50-b472-ce8f5c650708"
    let releaseReactNativeAppSecret = "a39df2ba-a3d2-4bb7-a44f-f0a7fe9c1718"
    let releaseCapacitorAppSecret = "e8e38b52-a50f-4c9b-bdc1-65730ef868a0"
    let releaseFlutterAppSecret = "eba32cd0-fe8f-43fc-8a1e-bbb69d45bbcc"
    let releaseXamarinAppSecret = "bdab471a-b950-40ac-937b-ab9e5dbf49f9"
    let releaseMauiAppSecret = "583e8970-29bb-4f1a-ba43-f7c2170c4638"
    var appSecret: String {
        var secret: String
        if isCalledFromExampleApp() || isCalledFromSDKTests() {
            secret = debugAppSecret
            return secret
        }
        if isReactNativeSDK() {
           secret = releaseReactNativeAppSecret
        } else if isCapacitorSDK() {
            secret = releaseCapacitorAppSecret
        } else if isFlutterSDK() {
            secret = releaseFlutterAppSecret
        } else if isXamarinSDK() {
            secret = releaseXamarinAppSecret
        } else if isMauiSDK() {
            secret = releaseMauiAppSecret
        } else {
            secret = releaseAppSecret
        }
        return secret
    }

    let session: URLSession
    let userId: String
    let installId: String
    let runId: String

    private static let formatter = ISO8601DateFormatter()

    init(installId: String, userId: String, runId: String) {
        self.session = URLSession(configuration: .default)
        self.installId = installId
        self.userId = userId
        self.runId = runId
        upload(sessionStartWithRunId: runId)
    }

    func upload(sessionStartWithRunId runId: String) {
        let startSession = VSAppCenterAPILog.startSession(
            VSAppCenterAPIStartSession(
                id: UUID().uuidString,
                userId: userId,
                device: getVSAppCenterAPIDevice(),
                timestamp: formatTimestamp(timestamp: Date().timeIntervalSince1970),
                sid: runId
            )
        )
        upload(data: VSAppCenterAPIRequestData(logs: [startSession])) { _ in }
    }

    func upload(
        eventWithName name: String,
        properties: [String: String],
        completionHandler: @escaping (Bool) -> Void
    ) {
        upload(
            data: VSAppCenterAPIRequestData(logs: [
                .event(
                    VSAppCenterAPIEvent(
                        id: UUID().uuidString,
                        userId: userId,
                        device: getVSAppCenterAPIDevice(),
                        timestamp: formatTimestamp(timestamp: Date().timeIntervalSince1970),
                        sid: runId,
                        name: name,
                        properties: properties
                    )
                )
            ]),
            completionHandler: completionHandler
        )
    }

    func upload(crashLog: CrashLog, completionHandler: @escaping (Bool) -> Void) {
        var logs = [getVSAppCenterAPIErrorReport(crashLog)]
        if !crashLog.logs.isEmpty, let attachment = getVSAppCenterAPIErrorAttachment(crashLog) {
            logs.append(attachment)
        }
        upload(
            data: VSAppCenterAPIRequestData(logs: logs),
            completionHandler: completionHandler
        )
    }

    func upload(data: VSAppCenterAPIRequestData, completionHandler: @escaping (Bool) -> Void) {
        guard let url = URL(safeString: defaultUploadURL),
              let payload = try? JSONEncoder().encode(data) else {
            completionHandler(false)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(appSecret, forHTTPHeaderField: "App-Secret")
        request.addValue(installId, forHTTPHeaderField: "Install-ID")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let task = self.session.uploadTask(with: request, from: payload) { data, response, error in
            if (response as? HTTPURLResponse)?.statusCode == 200 {
                completionHandler(true)
            } else {
                Exponea.logger.log(
                    .error,
                    message: """
                    Uploading data to Visual Studio App Center failed.
                    Error: \(String(describing: error))
                    Status code: \(String(describing: (response as? HTTPURLResponse)?.statusCode))
                    Response: \(String(data: data ?? Data(), encoding: .utf8) ?? "")
                    """
                )
                completionHandler(false)
            }
        }
        task.resume()
    }

    func getVSAppCenterAPIErrorReport(_ log: CrashLog) -> VSAppCenterAPILog {
        if log.isFatal {
            return .fatalError(
                VSAppCenterAPIAppleErrorReport(
                    id: log.id,
                    userId: self.userId,
                    device: getVSAppCenterAPIDevice(),
                    exception: getVSAppCenterAPIException(log.errorData),
                    timestamp: formatTimestamp(timestamp: log.timestamp),
                    appLaunchTimestamp: formatTimestamp(timestamp: log.launchTimestamp),
                    sid: log.runId,
                    osExceptionType: log.errorData.type
                )
            )
        } else {
            return .nonFatalError(
                VSAppCenterAPIHandledErrorReport(
                    id: log.id,
                    userId: self.userId,
                    device: getVSAppCenterAPIDevice(),
                    exception: getVSAppCenterAPIException(log.errorData),
                    timestamp: formatTimestamp(timestamp: log.timestamp),
                    appLaunchTimestamp: formatTimestamp(timestamp: log.launchTimestamp),
                    sid: log.runId
                )
            )
        }
    }

    func getVSAppCenterAPIErrorAttachment(_ log: CrashLog) -> VSAppCenterAPILog? {
        guard let data = log.logs.joined(separator: "\n").data(using: .utf8) else {
            return nil
        }
        return .errorAttachment(
            VSAppCenterAPIErrorAttachment(
                id: UUID().uuidString,
                userId: self.userId,
                device: getVSAppCenterAPIDevice(),
                timestamp: formatTimestamp(timestamp: log.timestamp),
                sid: log.runId,
                errorId: log.id,
                data: data.base64EncodedString()
            )
        )
    }

    func formatTimestamp(timestamp: Double) -> String {
        return VSAppCenterTelemetryUpload.formatter.string(from: Date(timeIntervalSince1970: timestamp))
    }

    func getVSAppCenterAPIDevice() -> VSAppCenterAPIDevice {
        let appInfo = TelemetryUtility.appInfo
        return VSAppCenterAPIDevice(
            appNamespace: appInfo.appName,
            appVersion: "\(appInfo.appName)-\(appInfo.appVersion)",
            appBuild: appInfo.appBuild,
            sdkName: "ExponeaSDK.ios",
            sdkVersion: Exponea.version,
            osName: UIDevice.current.systemName,
            osVersion: UIDevice.current.systemVersion,
            model: UIDevice.current.model,
            locale: Locale.preferredLanguages[0]
        )
    }

    func getVSAppCenterAPIException(_ errorData: ErrorData) -> VSAppCenterAPIException {
        return VSAppCenterAPIException(
            type: errorData.type,
            message: errorData.message,
            frames: getVSAppCenterAPIStackFrames(errorData)
        )
    }

    func getVSAppCenterAPIStackFrames(_ errorData: ErrorData) -> [VSAppCenterAPIStackFrame] {
        return errorData.stackTrace.map { stackSymbol in
            let splitSymbol = stackSymbol
                .replacingOccurrences(
                    of: "\\s+",
                    with: " ",
                    options: .regularExpression
                )
                .split(separator: " ", maxSplits: 3)
            return VSAppCenterAPIStackFrame(
                address: String(splitSymbol[2]),
                code: String(stackSymbol)
            )
        }
    }
}
