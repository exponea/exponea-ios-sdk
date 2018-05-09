//
//  Loglevel.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 11/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// The `Loglevel` is used to distinguish between log messages level.
public enum LogLevel: Int {

    /// Disables all logging.
    case none = 0

    /// Used only for logging serious errors or breaking issues.
    case error = 1

    /// Used only for logging warnings and recommendations.
    case warning = 2

    /// Verbose logging will output information about all SDK actions, including warnings and errors
    /// as well as saving, uploading, tracking and other various events.
    case verbose = 3

    /// A textual representation of the `Loglevel` case that can be used in log output.
    public var name: String {
        switch self {
        case .none: return ""
        case .error: return "❗️ ERROR"
        case .warning: return "⚠️ WARNING"
        case .verbose: return "ℹ️ VERBOSE"
        }
    }
}
