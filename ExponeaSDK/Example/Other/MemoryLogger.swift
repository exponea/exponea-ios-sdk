//
//  MemoryLogger.swift
//  Example
//
//  Created by Dominik Hadl on 29/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import ExponeaSDK

protocol MemoryLoggerDelegate: class {
    func logUpdated()
}

class MemoryLogger: Logger {
    var logs: [String] = []
    weak var delegate: MemoryLoggerDelegate?

    override func log(_ level: LogLevel,
                      message: String,
                      fileName: String = #file,
                      line: Int = #line,
                      funcName: String = #function) -> Bool {
        // Don't log if logging level set too low.
        guard logLevel.rawValue >= level.rawValue else {
            return false
        }

        // For example app purposes, create log with less clutter
        logs.append("\(level.name): \(message)")

        // Get the SDK logging
        return super.log(level, message: message, fileName: fileName, line: line, funcName: funcName)
    }

    override func logMessage(_ message: String) {
        super.logMessage(message)

        DispatchQueue.main.async {
            self.delegate?.logUpdated()
        }
    }
}
