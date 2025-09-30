//
//  AppInboxCache.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 27/10/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//

import Foundation

final class AppInboxCache: AppInboxCacheType {
    static let appInboxFolder = "exponeasdk_app_inbox"
    static let appInboxFileName = "app_inbox.json"
    // we should use our own instance of filemanager, host app can implement delegate on default one
    private let fileManager: FileManager = FileManager()
    private let semaphore: DispatchQueue = DispatchQueue(label: "AppInboxCacheLockingQueue", attributes: .concurrent)
    private var data: AppInboxData!

    init() {
        self.data = loadDataFromLocalStorage()
    }

    private func getCacheDirectoryURL() -> URL? {
        guard let documentsDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        let dir = documentsDir.appendingPathComponent(AppInboxCache.appInboxFolder, isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            do {
                try fileManager.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
            } catch {
                return nil
            }
        }
        return dir
    }

    private func loadDataFromLocalStorage() -> AppInboxData {
        let resultData: AppInboxData
        if let directory = getCacheDirectoryURL(),
           let data = try? Data(contentsOf: directory.appendingPathComponent(AppInboxCache.appInboxFileName)) {
            do {
                let loadedData = try JSONDecoder().decode(AppInboxData.self, from: data)
                if areValid(loadedData) {
                    resultData = loadedData
                } else {
                    resultData = AppInboxData()
                }
            } catch let error {
                Exponea.logger.log(.error, message: "Error getting stored AppInbox messages \(error.localizedDescription)")
                resultData = AppInboxData()
            }
        } else {
            Exponea.logger.log(.error, message: "Error getting stored AppInbox messages: Unable to create directory")
            resultData = AppInboxData()
        }
        return resultData
    }

    /// Older SDK may store AppInboxData with MessageItem without required data.
    /// We have to check and remove them in that case
    private func areValid(_ data: AppInboxData) -> Bool {
        return data.messages.allSatisfy { msg in
            msg.syncToken != nil && !msg.customerIds.isEmpty
        }
    }

    private func storeData() {
        guard
            let jsonData = try? JSONEncoder().encode(self.data),
            let jsonString = String(data: jsonData, encoding: .utf8),
            let directory = getCacheDirectoryURL() else {
                Exponea.logger.log(.error, message: "Unable to serialize AppInbox data.")
                return
        }
        do {
            try jsonString.write(
                to: directory.appendingPathComponent(AppInboxCache.appInboxFileName),
                atomically: true,
                encoding: .utf8
            )
        } catch let error {
            Exponea.logger.log(.error, message: "Saving AppInbox to file failed: \(error.localizedDescription)")
        }
    }

    func setMessages(messages: [MessageItem]) {
        data.messages = messages.sorted { msg1, msg2 in
            msg1.receivedTime > msg2.receivedTime
        }
        storeData()
    }

    func getMessages() -> [MessageItem] {
        return data.messages
    }

    func addMessages(messages: [MessageItem]) {
        let currentMessages = data.messages
        let allMessages = currentMessages + messages
        let uniqueMessages = [String: MessageItem](
            allMessages.map { ($0.id, $0) },
            uniquingKeysWith: { (_, last) in last }
        )
        setMessages(messages: Array(uniqueMessages.values))
    }

    func deleteImages(except: [String]) {
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
            if  fileName != AppInboxCache.appInboxFileName && !exceptFileNames.contains(fileName) {
                try? fileManager.removeItem(at: url)
            }
        }
    }

    func hasImageData(at imageUrl: String) -> Bool {
        guard let directory = getCacheDirectoryURL() else {
            Exponea.logger.log(.warning, message: "Unable to get AppInbox image cache directory")
            return false
        }
        let fileUrl = directory.appendingPathComponent(FileUtils.getFileName(fileUrl: imageUrl))
        let exists = fileManager.fileExists(atPath: fileUrl.path)
        if !exists {
            Exponea.logger.log(.verbose, message: "AppInbox image \(imageUrl) not found in cache.")
        }
        return exists
    }

    func saveImageData(at imageUrl: String, data: Data) {
        guard let directory = getCacheDirectoryURL() else {
            return
        }
        let fileUrl = directory.appendingPathComponent(FileUtils.getFileName(fileUrl: imageUrl))
        try? data.write(to: fileUrl, options: .atomic)
    }

    func getImageData(at imageUrl: String) -> Data? {
        guard let directory = getCacheDirectoryURL() else {
            return nil
        }
        let fileUrl = directory.appendingPathComponent(FileUtils.getFileName(fileUrl: imageUrl))
        return try? Data(contentsOf: fileUrl)
    }

    func setSyncToken(token: String?) {
        data.token = token
        storeData()
    }

    func getSyncToken() -> String? {
        data.token
    }

    func clear() {
        deleteImages(except: [])
        setMessages(messages: [])
        setSyncToken(token: nil)
    }
}

private class AppInboxData: Codable {
    var messages: [MessageItem] = []
    var token: String?
}
