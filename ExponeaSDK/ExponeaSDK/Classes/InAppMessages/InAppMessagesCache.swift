//
//  InAppMessagesCache.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 29/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import UIKit

final class InAppMessagesCache: InAppMessagesCacheType {
    static let inAppMessagesFolder = "exponeasdk_in_app_messages"
    static let inAppMessagesFileName = "in-app-messages.json"
    // we should use our own instance of filemanager, host app can implement delegate on default one
    private let fileManager: FileManager = FileManager()

    private func getCacheDirectoryURL() -> URL? {
        guard let documentsDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
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
        guard !IntegrationManager.shared.isStopped else {
            Exponea.logger.log(
                .error,
                message: "In-app UI is unavailable, SDK is stopping"
            )
            return
        }
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

    func deleteAllMessages() {
        guard let directory = getCacheDirectoryURL()?.appendingPathComponent(InAppMessagesCache.inAppMessagesFileName) else {
                Exponea.logger.log(.warning, message: "Unable to serialize in-app messages data.")
                return
        }
        try? fileManager.removeItem(at: directory)
    }

    func getInAppMessages() -> [InAppMessage] {
        if let directory = getCacheDirectoryURL(),
           let data = try? Data(contentsOf: directory.appendingPathComponent(InAppMessagesCache.inAppMessagesFileName)) {
            do {
                return try JSONDecoder().decode([InAppMessage].self, from: data)
            } catch {
                return []
            }
        }
        return []
    }

    private func extractFont(base64: String?, size: CGFloat?) -> UIFont? {
        if let base64 = base64,
           let data = Data(base64Encoded: base64),
           let dataProvider = CGDataProvider(data: data as CFData),
           let cgFont = CGFont(dataProvider) {
            var error: Unmanaged<CFError>?
            if CTFontManagerRegisterGraphicsFont(cgFont, &error) {
                var fontToReturn: UIFont?
                if let fontName = cgFont.postScriptName as? String {
                    fontToReturn = UIFont(name: fontName, size: size ?? 13)
                }
                CTFontManagerUnregisterGraphicsFont(cgFont, &error)
                return fontToReturn
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    func getInAppMessagesTimestamp() -> TimeInterval {
        guard let directory = getCacheDirectoryURL(),
              let attributes = try? fileManager.attributesOfItem(
                atPath: directory.appendingPathComponent(InAppMessagesCache.inAppMessagesFileName).path
              ),
              let modificationDate = attributes[FileAttributeKey.modificationDate] as? Date
        else {
            return 0
        }
        return modificationDate.timeIntervalSince1970
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
            if  fileName != InAppMessagesCache.inAppMessagesFileName && !exceptFileNames.contains(fileName) {
                try? fileManager.removeItem(at: url)
            }
        }
    }

    func hasImageData(at imageUrl: String) -> Bool {
        guard let directory = getCacheDirectoryURL() else {
            Exponea.logger.log(.warning, message: "Unable to get in-app message image cache directory")
            return false
        }
        let fileUrl = directory.appendingPathComponent(FileUtils.getFileName(fileUrl: imageUrl))
        let exists = fileManager.fileExists(atPath: fileUrl.path)
        if !exists {
            Exponea.logger.log(.verbose, message: "In-app message image \(imageUrl) not found in cache.")
        }
        return exists
    }

    func saveImageData(at imageUrl: String, data: Data) {
        guard let directory = getCacheDirectoryURL() else {
            return
        }
        let fileUrl = directory.appendingPathComponent(FileUtils.getFileName(fileUrl: imageUrl))
        do {
            try data.write(to: fileUrl, options: .atomic)
        } catch {
            Exponea.logger.log(.error, message: "In-app message image \(imageUrl) failed to be stored: \(error)")
        }
    }

    func getImageData(at imageUrl: String) -> Data? {
        guard let directory = getCacheDirectoryURL() else {
            return nil
        }
        let fileUrl = directory.appendingPathComponent(FileUtils.getFileName(fileUrl: imageUrl))
        return try? Data(contentsOf: fileUrl)
    }

    func clear() {
        deleteImages(except: [])
        deleteAllMessages()
    }
}
