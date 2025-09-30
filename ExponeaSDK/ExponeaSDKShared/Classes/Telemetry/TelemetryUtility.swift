//
//  TelemetryUtility.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 18/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

public final class TelemetryUtility {
    static let telemetryInstallId = "EXPONEA_TELEMETRY_INSTALL_ID"
    
    public static func isSDKRelated(stackTrace: [String]) -> Bool {
        return stackTrace.joined().contains("Exponea") || stackTrace.joined().contains("exponea")
    }
    
    public static func getInstallId(userDefaults: UserDefaults) -> String {
        if let installId = userDefaults.string(forKey: telemetryInstallId) {
            return installId
        }
        let installId = UUID().uuidString
        userDefaults.set(installId, forKey: telemetryInstallId)
        return installId
    }
    
    public static func formatConfigurationForTracking(_ config: Configuration) -> [String: String] {
        guard let defaultConfig = try? Configuration(
            projectToken: "placeholder",
            authorization: .none,
            baseUrl: Constants.Repository.baseUrl,
            allowDefaultCustomerProperties: true,
            manualSessionAutoClose: config.manualSessionAutoClose
        ) else {
            return [:]
        }
        return [
            "projectMapping":
                config.projectMapping != nil && config.projectMapping?.isEmpty == false ? "[REDACTED]" : "",
            "authorization":
                config.authorization == .none ? "[]" : "[REDACTED]",
            "baseUrl":
                "\(config.baseUrl)\(config.baseUrl == defaultConfig.baseUrl ? " [default]" : "")",
            "inAppContentBlocksPlaceholders":
                config.inAppContentBlocksPlaceholders == defaultConfig.inAppContentBlocksPlaceholders
            ? "[default]"
            : TelemetryUtility.toJson(config.inAppContentBlocksPlaceholders ?? []),
            "defaultProperties":
                config.defaultProperties != nil && config.defaultProperties?.isEmpty == false ? "[REDACTED]" : "",
            "sessionTimeout":
                "\(config.sessionTimeout)\(config.sessionTimeout == defaultConfig.sessionTimeout ? " [default]" : "")",
            "automaticSessionTracking":
                "\(config.automaticSessionTracking)"
            + "\(config.automaticSessionTracking == defaultConfig.automaticSessionTracking ? " [default]" : "")",
            "automaticPushNotificationTracking":
                "\(config.automaticPushNotificationTracking)"
            + "\(config.automaticPushNotificationTracking == defaultConfig.automaticPushNotificationTracking ? " [default]" : "")",
            "requirePushAuthorization":
                "\(config.requirePushAuthorization)"
            + "\(config.requirePushAuthorization == defaultConfig.requirePushAuthorization ? " [default]" : "")",
            "tokenTrackFrequency":
                "\(config.tokenTrackFrequency)"
            + "\(config.tokenTrackFrequency == defaultConfig.tokenTrackFrequency ? " [default]" : "")",
            "appGroup":
                String(describing: config.appGroup),
            "flushEventMaxRetries":
                "\(config.flushEventMaxRetries)"
            + "\(config.flushEventMaxRetries == defaultConfig.flushEventMaxRetries ? " [default]" : "")",
            "allowDefaultCustomerProperties":
                "\(config.allowDefaultCustomerProperties)"
            + "\(config.allowDefaultCustomerProperties == defaultConfig.allowDefaultCustomerProperties ? " [default]": "")",
            "advancedAuthEnabled":
                "\(config.advancedAuthEnabled)"
            + "\(config.advancedAuthEnabled == defaultConfig.advancedAuthEnabled ? " [default]" : "")",
            "customAuthProvider":
                "\(config.customAuthProvider == nil ? "none" : "registered")",
            "isDarkModeEnabled":
                (config.isDarkModeEnabled?.description ?? "nil")
            + "\(config.isDarkModeEnabled == defaultConfig.isDarkModeEnabled ? " [default]" : "")",
            "appInboxDetailImageInset":
                (config.appInboxDetailImageInset?.description ?? "nil")
            + "\(config.appInboxDetailImageInset == defaultConfig.appInboxDetailImageInset ? " [default]" : "")",
            "manualSessionAutoClose":
                "\(config.manualSessionAutoClose)"
            + "\(config.manualSessionAutoClose == defaultConfig.manualSessionAutoClose ? " [default]" : "")",
            "application_id": Constants.General.applicationID
        ]
    }
    
    private static func getPlistValue(bundle: Bundle = Bundle.main, key: String, defaultValue: String = "") -> String {
        return bundle.infoDictionary?[key] as? String ?? defaultValue
    }
    
    public struct AppInfo {
        public let appIdentifier: String
        public let appName: String
        public let appVersion: String
        public let appBuild: String
    }
    
    public static var appInfo: AppInfo {
        return AppInfo(
            appIdentifier: getPlistValue(key: "CFBundleIdentifier"),
            appName: getPlistValue(key: "CFBundleDisplayName", defaultValue: getPlistValue(key: "CFBundleName")),
            appVersion: getPlistValue(key: "CFBundleShortVersionString"),
            appBuild: getPlistValue(key: "CFBundleVersion")
        )
    }
    
    public static func getCurrentThreadInfo() -> ThreadInfo {
        let posixThread = pthread_self()
        let swiftThread = Thread.current
        return ThreadInfo(
            id: pthread_mach_thread_np(posixThread),
            name: swiftThread.name ?? "",
            state: translateThreadState(swiftThread),
            isDaemon: false,
            isCurrent: true,
            isMain: swiftThread.isMainThread,
            stackTrace: []
        )
    }
    
    static func updateThreadInfo(from thread: ThreadInfo, with stacktrace: [String]) -> ThreadInfo {
        let currentPossixThreadId = pthread_mach_thread_np(pthread_self())
        return ThreadInfo(
            id: thread.id,
            name: thread.name,
            state: thread.state,
            isDaemon: thread.isDaemon,
            isCurrent: currentPossixThreadId == thread.id,
            isMain: thread.isMain,
            stackTrace: parseStackTrace(stacktrace)
        )
    }
    
    static func readStackTraceInfo(_ source: NSException) -> [ErrorStackTraceElement] {
        return parseStackTrace(source.callStackSymbols)
    }
    
    private static func translateThreadState(_ origin: Thread) -> String {
        if origin.isExecuting {
            return "running"
        }
        if origin.isCancelled {
            return "cancelled"
        }
        if origin.isFinished {
            return "done"
        }
        return "new"
    }
    
    static func parseStackTrace(_ from: [String]) -> [ErrorStackTraceElement] {
        return from.compactMap { parseStackTraceLine($0) }
    }
    
    // Parses line from stacktrace. Supports format `[Index] [ModuleName] [MemoryAddress] [SymbolName] + [Offset]`.
    // Example of line: ``
    private static func parseStackTraceLine(_ line: String) -> ErrorStackTraceElement? {
        let symbolComponents = line
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression, range: nil)
            .split(separator: " ", maxSplits: 3)
        guard symbolComponents.count == 4 else {
            return nil
        }
        let symbolPart = symbolComponents[3]
        var symbolName = String(symbolPart)
        var lineNumber = 0
        if let plusInSymbol = symbolPart.range(of: " + ") {
            symbolName = String(symbolPart[..<plusInSymbol.lowerBound])
            if let lineNumberAsInt = Int(symbolPart[plusInSymbol.upperBound...].trimmingCharacters(in: .whitespaces)) {
                lineNumber = lineNumberAsInt
            }
        }
        return ErrorStackTraceElement(
            symbolAddress: String(symbolComponents[2]),
            symbolName: symbolName,
            module: String(symbolComponents[1]),
            lineNumber: lineNumber
        )
    }
    
    public static func toJson(_ obj: [[String: String]]) -> String {
        guard let json = try? JSONSerialization.data(withJSONObject: obj) else { return "" }
        return String(data: json, encoding: .utf8) ?? ""
    }
    
    public static func toJson(_ obj: [String]) -> String {
        guard let json = try? JSONSerialization.data(withJSONObject: obj) else { return "" }
        return String(data: json, encoding: .utf8) ?? ""
    }
    
    public static func readTelemetryEvents(_ repository: UserDefaults) -> [EventLog] {
        guard let eventsData = repository.data(forKey: Constants.General.telemetryEvents),
              let events = try? JSONDecoder().decode([EventLog].self, from: eventsData) else {
            // unable to parse, there is breaking issue
            repository.removeObject(forKey: Constants.General.telemetryEvents)
            return []
        }
        return events
    }
    
    public static func saveTelemetryEvents(_ target: UserDefaults, _ data: [EventLog]) {
        guard let eventsData = try? JSONEncoder().encode(data) else {
            return
        }
        target.set(eventsData, forKey: Constants.General.telemetryEvents)
    }

    // Returns UserDefaults instance. If App is using extensions then appgroup has to be configured for SDK
    // Suitename for given AppGroup is used with priority
    // If app is not using extensions, therefore appGroup is NIL, then "ExponeaSDK" suitename is used
    // If app defines AppGroup but is configured incorrectly then `standard` UserDefaults are used as fallback
    public static func getUserDefaults(appGroup: String?) -> UserDefaults {
        let sdkSuiteName = appGroup ?? Constants.General.userDefaultsSuite
        return UserDefaults(suiteName: sdkSuiteName) ?? UserDefaults.standard
    }

    public static func readAsString(_ source: Any?, _ defaultValue: String = "") -> String {
        if let source {
            return String(describing: source)
        } else {
            return defaultValue
        }
    }
}
