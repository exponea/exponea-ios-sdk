//
//  ThreadInfo.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 28/06/2025.
//  Copyright © 2025 Exponea. All rights reserved.
//

import Foundation

public struct ThreadInfo: Codable {
    let id: UInt32
    let name: String
    let state: String
    let isDaemon: Bool
    let isCurrent: Bool
    let isMain: Bool
    let stackTrace: [ErrorStackTraceElement]
}
