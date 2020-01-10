//
//  InAppMessagesCache.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 29/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

final class InAppMessagesCache: InAppMessagesCacheType {
    static let inAppMessagesFolder = "exponeasdk_in_app_messages"
    static let inAppMessagesFileName = "in-app-messages.json"
    // we should use our own instance of filemanager, host app can implement delegate on default one
    private let fileManager: FileManager = FileManager()

    private func getCacheDirectoryURL() -> URL? {
        guard let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let dir = documentsDir.appendingPathComponent(InAppMessagesCache.inAppMessagesFolder, isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            do {
                try fileManager.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
            } catch {
                return nil
            }
        }
        return dir
    }

    func saveInAppMessages(inAppMessages: [InAppMessage]) {
        guard let jsonData = try? JSONEncoder().encode(inAppMessages),
            let jsonString = String(data: jsonData, encoding: .utf8),
            let directory = getCacheDirectoryURL() else {
                Exponea.logger.log(.warning, message: "Unable to serialize in-app messages data.")
                return
        }
        do {
            try jsonString.write(
                to: directory.appendingPathComponent(InAppMessagesCache.inAppMessagesFileName),
                atomically: true,
                encoding: .utf8
            )
        } catch {
            Exponea.logger.log(.warning, message: "Saving in-app messages to file failed.")
        }
    }

    func getInAppMessages() -> [InAppMessage] {
        if let directory = getCacheDirectoryURL(),
            let data = try? Data(
                contentsOf: directory.appendingPathComponent(InAppMessagesCache.inAppMessagesFileName)
            ),
            let inAppMessages = try? JSONDecoder().decode([InAppMessage].self, from: data) {
            return inAppMessages
        }
        return []
    }

    private func getFileName(imageUrl: String) -> String {
        guard let data = imageUrl.data(using: .utf8) else {
            return imageUrl
        }
        return data
            .base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: "/", with: "")
    }

    func deleteImages(except: [String]) {
        let exceptFileNames = except.map { getFileName(imageUrl: $0) }
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
            if  fileName != InAppMessagesCache.inAppMessagesFileName && !exceptFileNames.contains(fileName) {
                try? fileManager.removeItem(at: url)
            }
        }
    }

    func hasImageData(at imageUrl: String) -> Bool {
        guard let directory = getCacheDirectoryURL() else {
            return false
        }
        let fileUrl = directory.appendingPathComponent(getFileName(imageUrl: imageUrl))
        return fileManager.fileExists(atPath: fileUrl.path)
    }

    func saveImageData(at imageUrl: String, data: Data) {
        guard let directory = getCacheDirectoryURL() else {
            return
        }
        let fileUrl = directory.appendingPathComponent(getFileName(imageUrl: imageUrl))
        try? data.write(to: fileUrl, options: .atomic)
    }

    func getImageData(at imageUrl: String) -> Data? {
        guard let directory = getCacheDirectoryURL() else {
            return nil
        }
        let fileUrl = directory.appendingPathComponent(getFileName(imageUrl: imageUrl))
        return try? Data(contentsOf: fileUrl)
    }

    func clear() {
        deleteImages(except: [])
        saveInAppMessages(inAppMessages: [])
    }
}
