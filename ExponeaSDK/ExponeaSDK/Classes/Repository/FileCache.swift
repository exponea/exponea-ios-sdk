//
//  FileCache.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 06/07/2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation

final class FileCache: FileCacheType {
    
    static let shared = FileCache()

    static let inAppMessagesFolder = "exponeasdk_files_cache"

    private let fileManager: FileManager = FileManager()

    private func getCacheDirectoryURL() -> URL? {
        guard let documentsDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        let dir = documentsDir.appendingPathComponent(FileCache.inAppMessagesFolder, isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            do {
                try fileManager.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
            } catch {
                return nil
            }
        }
        return dir
    }

    func deleteFiles(except: [String]) {
        let exceptFileNames = except.map { FileUtils.getFileName(fileUrl: $0) }
        guard let directory = getCacheDirectoryURL() else {
            return
        }
        let fileURLs = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: []
        )
        fileURLs?.forEach { url in
            let fileName = url.lastPathComponent
            if !exceptFileNames.contains(fileName) {
                try? fileManager.removeItem(at: url)
            }
        }
    }

    func hasFileData(at fileUrl: String) -> Bool {
        guard let directory = getCacheDirectoryURL() else {
            Exponea.logger.log(.warning, message: "Unable to get file cache directory")
            return false
        }
        let fileUrl = directory.appendingPathComponent(FileUtils.getFileName(fileUrl: fileUrl))
        let exists = fileManager.fileExists(atPath: fileUrl.path)
        if !exists {
            Exponea.logger.log(.verbose, message: "File \(fileUrl) not found in cache.")
        }
        return exists
    }

    func saveFileData(at fileUrl: String, data: Data) {
        guard let directory = getCacheDirectoryURL() else {
            return
        }
        let filePath = directory.appendingPathComponent(FileUtils.getFileName(fileUrl: fileUrl))
        try? data.write(to: filePath, options: .atomic)
    }

    func getFileData(at fileUrl: String) -> Data? {
        guard let directory = getCacheDirectoryURL() else {
            return nil
        }
        let filePath = directory.appendingPathComponent(FileUtils.getFileName(fileUrl: fileUrl))
        return try? Data(contentsOf: filePath)
    }

    func clear() {
        deleteFiles(except: [])
    }

    func getOrDownloadFile(at fileUrl: String) -> Data? {
        if fileUrl.isEmpty {
            return nil
        }
        var fileData = getFileData(at: fileUrl)
        if fileData == nil {
            fileData = FileUtils.tryDownloadFile(fileUrl)
            if let fileData = fileData {
                saveFileData(at: fileUrl, data: fileData)
            }
        }
        return fileData
    }
}
