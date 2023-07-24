//
//  FileUtils.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 06/07/2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation

struct FileUtils {
    /// Downloads file from given URL.
    /// Method has to be called within background thread due to sync implementation.
    public static func tryDownloadFile(_ fileSource: String?) -> Data? {
        guard let fileSource = fileSource,
              let fileUrl = URL(string: fileSource) else {
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
}
