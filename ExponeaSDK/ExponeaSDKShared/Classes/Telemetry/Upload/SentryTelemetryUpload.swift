//
//  SentryTelemetryUpload.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 01/07/2025.
//  Copyright © 2025 Exponea. All rights reserved.
//

import Foundation
import UIKit

public class SentryTelemetryUpload: TelemetryUpload {

    #if DEBUG
    let environment = "debug"
    #else
    let environment = "release"
    #endif

    let session: URLSession
    let installId: String

    private let dateFormat = ISO8601DateFormatter()
    private let dsn: String
    private let sentryUserinfo: String
    private let sentryHostname: String
    private let sentryProject: String
    private let sentryEnvelopeApiUrl: URL?
    private let appInfo = TelemetryUtility.appInfo
    private let stackTraceFramesLimit = 100
    private let sentryClientVersion = "sentry.cocoa/8.52.1"
    private let sdkConfigGetter: () -> Configuration?

    public init(installId: String, configGetter: @escaping () -> Configuration?) {
        self.session = URLSession(configuration: .default)
        self.installId = installId
        self.dsn = SentryTelemetryUpload.chooseDsn()
        let dsnUrl = URL(sharedSafeString: dsn)
        self.sentryUserinfo = dsnUrl?.user ?? ""
        self.sentryHostname = dsnUrl?.host ?? ""
        self.sentryProject = dsnUrl?.lastPathComponent ?? ""
        self.sentryEnvelopeApiUrl = URL(sharedSafeString: "https://\(sentryHostname)/api/\(sentryProject)/envelope/")
        self.sdkConfigGetter = configGetter
    }
    
    private static func chooseDsn() -> String {
        if BuildConfigurationShared.isCalledFromExampleApp() || BuildConfigurationShared.isCalledFromSDKTests() {
            // Use dev sentry project when SDK is used in our demo app
            return "https://0c1ab20fe28a048ab96370522875d4f6@msdk.bloomreach.co/10"
        }
        if BuildConfigurationShared.isReactNativeSDK() {
            return "https://7b7e9339154a17cf1ca82764cb04495b@msdk.bloomreach.co/5"
        } else if BuildConfigurationShared.isFlutterSDK() {
            return "https://152944e135210937670fefdfccd6543b@msdk.bloomreach.co/7"
        } else if BuildConfigurationShared.isXamarinSDK() {
            return "https://0f0d578e0143d6820109ae4f7390561d@msdk.bloomreach.co/12"
        } else if BuildConfigurationShared.isMauiSDK() {
            return "https://d4e8d3e1e9c44647f5f0ac54820adfef@msdk.bloomreach.co/9"
        }
        // iOS native SDK
        return "https://b952a5b2a33a11d7bf023879e8a9b070@msdk.bloomreach.co/3"
    }

    public func uploadSessionStart(runId: String, completionHandler: @escaping (Bool) -> Void) {
        sendSentryEnvelope(buildEnvelope(sessionId: runId), completionHandler)
    }

    internal func buildEnvelope(sessionId: String) -> ExponeaSentryEnvelope<ExponeaSentrySession> {
        let now = Date()
        let sentAtString = dateFormat.string(from: now)
        let sequence = Int64(now.timeIntervalSince1970 * 1000)
        let envelopeHeader = ExponeaSentryEnvelopeHeader(
            eventId: nil,
            dsn: dsn,
            sentAt: sentAtString
        )
        let itemBody = ExponeaSentrySession(
            started: sentAtString,
            timestamp: sentAtString,
            distinctId: sessionId,
            sessionId: sessionId,
            isInit: true,
            status: "ok",
            sequence: sequence,
            attributes: ExponeaSentryAttributes(
                release: buildSentryReleaseInfo(),
                environment: environment
            ),
            extra: buildExtra(buildTags("sentrySession"))
        )
        let envelopeItem = ExponeaSentryEnvelopeItem(header: itemBody.prepareHeader(), body: itemBody)
        let sentryEnvelope = ExponeaSentryEnvelope(header: envelopeHeader, item: envelopeItem)
        return sentryEnvelope
    }

    public func upload(crashLog: CrashLog, completionHandler: @escaping (Bool) -> Void) {
        sendSentryEnvelope(buildEnvelope(crashLog: crashLog), completionHandler)
    }

    internal func buildEnvelope(crashLog: CrashLog) -> ExponeaSentryEnvelope<ExponeaSentryException> {
        let sentryEventId = crashLog.id.replacingOccurrences(of: "-", with: "").lowercased()
        let sentAtString = dateFormat.string(from: Date(timeIntervalSince1970: crashLog.timestamp))
        let envelopeHeader = ExponeaSentryEnvelopeHeader(
            eventId: sentryEventId,
            dsn: dsn,
            sentAt: sentAtString
        )
        let itemBody = ExponeaSentryException(
            timestamp: sentAtString,
            threads: ExponeaSentryValuesWrapper(values: extractThreads(crashLog)),
            exception: ExponeaSentryValuesWrapper(values: extractExceptionsQueue(crashLog)),
            level: toSentryErrorLevel(crashLog.isFatal),
            eventId: sentryEventId,
            contexts: buildContexts(),
            tags: buildTags("sentryError"),
            release: buildSentryReleaseInfo(),
            environment: environment,
            extra: buildExtra([:])
        )
        let envelopeItem = ExponeaSentryEnvelopeItem(header: itemBody.prepareHeader(), body: itemBody)
        let sentryEnvelope = ExponeaSentryEnvelope(header: envelopeHeader, item: envelopeItem)
        return sentryEnvelope
    }

    public func upload(eventLog: EventLog, completionHandler: @escaping (Bool) -> Void) {
        sendSentryEnvelope(buildEnvelope(eventLog: eventLog), completionHandler)
    }

    internal func buildEnvelope(eventLog: EventLog) -> ExponeaSentryEnvelope<ExponeaSentryMessage> {
        let sentryEventId = eventLog.id.replacingOccurrences(of: "-", with: "").lowercased()
        let sentAtString = dateFormat.string(from: Date(timeIntervalSince1970: eventLog.timestamp))
        let envelopeHeader = ExponeaSentryEnvelopeHeader(
            eventId: sentryEventId,
            dsn: dsn,
            sentAt: sentAtString
        )
        let itemBody = ExponeaSentryMessage(
            timestamp: sentAtString,
            message: ExponeaSentryMessageLog(formatted: eventLog.name),
            eventId: sentryEventId,
            contexts: buildContexts(),
            tags: buildTags(eventLog.name),
            release: buildSentryReleaseInfo(),
            environment: environment,
            extra: buildExtra(eventLog.properties)
        )
        let envelopeItem = ExponeaSentryEnvelopeItem(header: itemBody.prepareHeader(), body: itemBody)
        let sentryEnvelope = ExponeaSentryEnvelope(header: envelopeHeader, item: envelopeItem)
        return sentryEnvelope
    }
    
    private func buildExtra(_ origin: [String: String]) -> [String: String] {
        let appInfo = TelemetryUtility.appInfo
        var extra = [
            "sdkVersion": Exponea.version,
            "appName": appInfo.appIdentifier,
            "appVersion": appInfo.appVersion,
            "appNameVersion": "\(appInfo.appIdentifier) - \(appInfo.appVersion)",
            "appNameVersionSdkVersion": "\(appInfo.appIdentifier) - \(appInfo.appVersion) - SDK \(Exponea.version)"
        ]
        extra.merge(origin, uniquingKeysWith: { first, _ in return first })
        return extra
    }
    
    private func buildSentryReleaseInfo() -> String {
        return "\(appInfo.appName)@\(appInfo.appVersion) - SDK \(Exponea.version)"
    }
    
    private func buildTags(_ eventName: String) -> [String: String] {
        return [
            "uuid": installId,
            "projectToken": tryReadProjectToken(),
            "sdkVersion": Exponea.version,
            "sdkName": "ExponeaSDK.ios",
            "appName": appInfo.appName,
            "appVersion": appInfo.appVersion,
            "appBuild": appInfo.appBuild,
            "appIdentifier": appInfo.appIdentifier,
            "osName": UIDevice.current.systemName,
            "osVersion": UIDevice.current.systemVersion,
            "deviceModel": UIDevice.current.model,
            "deviceManufacturer": "Apple",
            "brand": "Apple",
            "locale": Locale.preferredLanguages[0],
            "eventName": eventName
        ]
    }
    
    private func tryReadProjectToken() -> String {
        return sdkConfigGetter()?.projectToken ?? ""
    }
    
    private func toSentryErrorLevel(_ isFatal: Bool) -> String {
        if isFatal {
            return "fatal"
        }
        return "error"
    }
    
    private func extractThreads(_ source: CrashLog) -> [ExponeaSentryThread] {
        return [ExponeaSentryThread(
            id: source.thread.id,
            name: source.thread.name,
            state: source.thread.state,
            crashed: source.isFatal,
            current: source.thread.isCurrent,
            daemon: source.thread.isDaemon,
            main: source.thread.isMain,
            stacktrace: ExponeaSentryStackTrace(frames: parseExceptionStackTrace(source.thread.stackTrace)))
        ]
    }
    
    private func parseExceptionStackTrace(_ stacktrace: [ErrorStackTraceElement]) -> [ExponeaSentryStackFrame] {
        return stacktrace.map { el in
            ExponeaSentryStackFrame(
                symbolAddress: el.symbolAddress,
                function: el.symbolName,
                module: el.module,
                lineno: max(el.lineNumber ?? 0, 0))
        }
        .prefix(stackTraceFramesLimit)
        .reversed()
    }
    
    private func extractExceptionsQueue(_ source: CrashLog) -> [ExponeaSentryExceptionPart] {
        return [ExponeaSentryExceptionPart(
            type: source.errorData.type,
            value: source.errorData.message,
            stacktrace: ExponeaSentryStackTrace(
                frames: parseExceptionStackTrace(source.errorData.stackTrace)
            ),
            mechanism: ExponeaSentryExceptionMechanism(
                type: "generic",
                description: "generic",
                handled: !source.isFatal
            ),
            threadId: source.thread.id
        )]
    }
    
    private func buildContexts() -> ExponeaSentryContext {
        return ExponeaSentryContext(
            app: ExponeaSentryAppContextInfo(
                appIdentifier: appInfo.appIdentifier,
                appName: appInfo.appName,
                appBuild: appInfo.appBuild
            ),
            device: ExponeaSentryDeviceContextInfo(
                model: UIDevice.current.model,
                manufacturer: "Apple",
                brand: "Apple"
            ),
            os: ExponeaSentryOsContextInfo(
                version: UIDevice.current.systemVersion
            )
        )
    }

    private func sendSentryEnvelope<T: ExponeaSentryEnvelopeItemBody>(
        _ envelope: ExponeaSentryEnvelope<T>,
        _ completionHandler: @escaping (Bool) -> Void
    ) {
        guard let url = sentryEnvelopeApiUrl else {
            Exponea.logger.log(
                .error,
                message: "Upload telemetry failed, URL is invalid"
            )
            completionHandler(false)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/x-sentry-envelope", forHTTPHeaderField: "Content-Type")
        request.addValue(sentryClientVersion, forHTTPHeaderField: "User-Agent")
        request.addValue("Sentry sentry_version=7,sentry_client=\(sentryClientVersion),sentry_key=\(sentryUserinfo)", forHTTPHeaderField: "X-Sentry-Auth")
        guard let payload = try? buildRequestPayload(envelope).data(using: .utf8) else {
            Exponea.logger.log(
                .error,
                message: "Upload telemetry failed, Data are invalid"
            )
            completionHandler(false)
            return
        }
        self.session.uploadTask(with: request, from: payload) { data, response, error in
            if (response as? HTTPURLResponse)?.statusCode == 200 {
                completionHandler(true)
            } else {
                Exponea.logger.log(
                    .error,
                    message: """
                    Uploading data to Sentry failed.
                    Error: \(String(describing: error))
                    Status code: \(String(describing: (response as? HTTPURLResponse)?.statusCode))
                    Response: \(String(data: data ?? Data(), encoding: .utf8) ?? "")
                    """
                )
                completionHandler(false)
            }
        }.resume()
    }
    
    private func buildRequestPayload<T: ExponeaSentryEnvelopeItemBody>(_ source:  ExponeaSentryEnvelope<T>) throws -> String {
        let messageHeaderJson = try toJson(source.header)
        let messageItemJson = try toJson(source.item.body)
        let messageItemHeaderJson = try toJson(source.item.header.withLength(newLength: messageItemJson.count))
        let multilineJsonContent = [messageHeaderJson, messageItemHeaderJson, messageItemJson].joined(separator: "\n")
        return multilineJsonContent
    }
    
    private func toJson(_ orig: Encodable) throws -> String {
        if let json = String(data: try JSONEncoder().encode(orig), encoding: .utf8) {
            return json
        }
        throw ExponeaError.unknownError("Unable to serialize telemetry payload")
    }
}
