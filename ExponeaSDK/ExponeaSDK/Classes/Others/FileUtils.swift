//
//  FileUtils.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 06/07/2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation
import CryptoKit

struct FileUtils {
    /// Downloads file from given URL.
    /// Method has to be called within background thread due to sync implementation.
    public static func tryDownloadFile(_ fileSource: String?) -> Data? {
        guard let fileSource = fileSource,
              let fileUrl = URL(safeString: fileSource) else {
            Exponea.logger.log(.error, message: "File cannot be downloaded \(fileSource ?? "<is nil>")")
            return nil
        }
        let semaphore = DispatchSemaphore(value: 0)
        var fileData: Data?
        let dataTask = URLSession.shared.dataTask(with: fileUrl) { data, _, _ in {
            fileData = data
            semaphore.signal()
        }() }
        dataTask.resume()
        let awaitResult = semaphore.wait(timeout: .now() + 10.0)
        switch awaitResult {
        case .success:
            // Nothing to do, let check fileData
            break
        case .timedOut:
            Exponea.logger.log(.warning, message: "File \(fileSource) may be too large or slow connection - aborting")
            dataTask.cancel()
        }
        return fileData
    }

    public static func getFileName(fileUrl: String) -> String {
        guard let urlAsData = fileUrl.data(using: .utf8) else {
            return fileUrl
        }
        return SHA512.hash(data: urlAsData)
            .compactMap { String(format: "%02x", $0) }
            .joined()
    }
}
