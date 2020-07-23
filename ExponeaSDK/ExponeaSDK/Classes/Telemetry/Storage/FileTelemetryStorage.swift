//
//  FileTelemetryStorage.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 15/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

class FileTelemetryStorage: TelemetryStorage {
    let crashLogFolder = "exponeasdk_telemetry_storage"
    let crashLogFilePrefix = "exponeasdk_crashlog_"

    // we should use our own instance of filemanager, host app can implement delegate on default one
    let fileManager: FileManager

    init() {
        fileManager = FileManager()
    }

    func makeCacheDirectory() -> URL? {
        guard let libraryDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        let dir = libraryDir.appendingPathComponent(crashLogFolder, isDirectory: true)
        if !fileManager.fileExists(atPath: dir.absoluteString) {
            do {
                try fileManager.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
            } catch {
                return nil
            }
        }
        return dir
    }

    func getFileURL(_ log: CrashLog) -> URL? {
        guard let dir = makeCacheDirectory() else {
            return nil
        }
        return dir.appendingPathComponent("\(crashLogFilePrefix)\(log.id).json")
    }

    func saveCrashLog(_ log: CrashLog) {
        guard let jsonData = try? JSONEncoder().encode(log),
            let jsonString = String(data: jsonData, encoding: .utf8),
            let fileURL = getFileURL(log) else {
                Exponea.logger.log(.warning, message: "Unable to serialize crash log")
                return
        }
        try? jsonString.write(to: fileURL, atomically: false, encoding: .utf8)
    }

    func deleteCrashLog(_ log: CrashLog) {
        if let url = getFileURL(log) {
            try? fileManager.removeItem(at: url)
        }
    }

    func getAllCrashLogs() -> [CrashLog] {
        guard let dir = makeCacheDirectory() else {
            return []
        }
        var crashLogs: [CrashLog] = []
        let fileURLs = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil, options: [])
        fileURLs?.forEach { url in
            if url.lastPathComponent.contains(crashLogFilePrefix) {
                if let data = try? Data(contentsOf: url),
                   let crashLog = try? JSONDecoder().decode(CrashLog.self, from: data) {
                    crashLogs.append(crashLog)
                } else {
                    try? fileManager.removeItem(at: url)
                }
            }
        }
        return crashLogs.sorted(by: { $0.timestamp < $1.timestamp })
    }
}
