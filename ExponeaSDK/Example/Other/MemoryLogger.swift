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
        
        // Print our log
        logMessage("\(level.name): \(message)")
        return true
    }
    
    override func logMessage(_ message: String) {
        logs.append(message)
        
        print(message)
        
        DispatchQueue.main.async {
            self.delegate?.logUpdated()
        }
    }
}
