//
//  ErrorStackTraceElement.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 28/06/2025.
//  Copyright © 2025 Exponea. All rights reserved.
//

import Foundation

internal struct ErrorStackTraceElement: Codable, Equatable {
    let symbolAddress: String?
    let symbolName: String?
    let module: String?
    let lineNumber: Int?
}
