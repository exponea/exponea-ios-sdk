//
//  VSAppCenterTelemetryUpload.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 18/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

final class VSAppCenterTelemetryUpload: TelemetryUpload {
    let defaultUploadURL = "https://in.appcenter.ms/logs?Api-Version=1.0.0"
    let appSecret = "7172e098-ec8e-4d1b-9f9e-3e5107d8b22a"

    let session: URLSession
    let userId: String
    let installId: String

    private static let formatter = ISO8601DateFormatter()

    init(installId: String, userId: String) {
        self.session = URLSession(configuration: .default)
        self.installId = installId
        self.userId = userId
    }

    func upload(crashLog: CrashLog, completionHandler: @escaping (Bool) -> Void) {
        upload(
            data: VSAppCenterAPIRequestData(logs: [getVSAppCenterAPIErrorReport(crashLog)]),
            completionHandler: completionHandler
        )
    }

    func upload(data: VSAppCenterAPIRequestData, completionHandler: @escaping (Bool) -> Void) {
        guard let url = URL(string: defaultUploadURL),
              let payload = try? JSONEncoder().encode(data) else {
            completionHandler(false)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(appSecret, forHTTPHeaderField: "App-Secret")
        request.addValue(installId, forHTTPHeaderField: "Install-ID")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let task = self.session.uploadTask(with: request, from: payload) {data, response, error in
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
                    appLaunchTimestamp: formatTimestamp(timestamp: log.launchTimestamp)
                )
            )
        }
    }

    func formatTimestamp(timestamp: Double) -> String {
        return VSAppCenterTelemetryUpload.formatter.string(from: Date(timeIntervalSince1970: timestamp))
    }

    func getPlistValue(bundle: Bundle = Bundle.main, key: String, defaultValue: String = "") -> String {
        return Bundle.main.infoDictionary?[key] as? String ?? defaultValue
    }

    func getVSAppCenterAPIDevice() -> VSAppCenterAPIDevice {
        let bundleIdentifier = getPlistValue(key: "CFBundleIdentifier")
        return VSAppCenterAPIDevice(
            appNamespace: bundleIdentifier,
            appVersion: "\(bundleIdentifier)-\(getPlistValue(key: "CFBundleShortVersionString"))",
            appBuild: getPlistValue(key: "CFBundleVersion"),
            sdkName: "ExponeaSDK.ios",
            sdkVersion: getPlistValue(bundle: Bundle(for: ExponeaSDK.Exponea.self), key: "CFBundleShortVersionString"),
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
