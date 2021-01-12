//
//  Logger.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 11/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// A logger class used to log errors, warnings and other debug information. This class can be subclassed
/// and the logging behaviour changed as you wish. By default it prints everything to the console.
open class Logger {

    /// Date formatter is used for timestamps in the log. Default date format is `yyyy-MM-dd hh:mm:ssSSS`.
    public let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd hh:mm:ssSSS"
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    /// Default level of logging is set to `.warning`.
    open var logLevel: LogLevel = .warning

    private var logHooks: [String: (String) -> Void] = [:]

    required public init() { }

    /// Main log function used to log messages with appropriate level along with additional debug information.
    /// By default this function prints everything to the console, if the log level is set high enough.
    ///
    /// - Parameters:
    ///   - level: The severity of the message you want to log. See `LogLevel` for more information.
    ///   - message: Message you want to print along with the log.
    ///   - fileName: Name of the file that the log originated from.
    ///   - line: Line from which the log function was called or the log is related to.
    ///   - funcName: Name of the parent function that called the log function or other related function.
    @discardableResult
    open func log(_ level: LogLevel,
                  message: String,
                  fileName: String = #file,
                  line: Int = #line,
                  funcName: String = #function) -> Bool {

        // Don't log if logging level set too low.
        guard logLevel.rawValue >= level.rawValue else {
            return false
        }

        // Get date
        let date = dateFormatter.string(from: Date())

        // Get file name
        let file = sourceFile(from: fileName)

        // Print our log
        logMessage("\(date) ExponeaSDK \(level.name) [\(file)]:\(line) \(funcName): \(message)")
        return true
    }

    /// Used to log the actual log message to console.
    ///
    /// - Parameter message: The message you want to log.
    open func logMessage(_ message: String) {
        logHooks.forEach { $0.value(message) }
        print(message)
    }

    public func addLogHook(_ hook: @escaping (String) -> Void) -> String {
        let id = UUID().uuidString
        logHooks[id] = hook
        return id
    }

    public func removeLogHook(with id: String) {
        logHooks.removeValue(forKey: id)
    }

    /// Returns the source file name from a provided a file path.
    ///
    /// - Parameter filePath: The file path for the source file.
    /// - Returns: If a file path is valid, returns source file name, otherwise returns provided file path.
    public func sourceFile(from filePath: String) -> String {
        let components = filePath.components(separatedBy: "/")
        return components.last!
    }
}
