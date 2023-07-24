//
//  FileCacheType.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 06/07/2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation

protocol FileCacheType {
    func deleteFiles(except: [String])
    func hasFileData(at fileUrl: String) -> Bool
    func saveFileData(at fileUrl: String, data: Data)
    func getFileData(at fileUrl: String) -> Data?
    func clear()
}
