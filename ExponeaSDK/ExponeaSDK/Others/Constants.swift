//
//  Constants.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 05/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// enum with constants used through the SDK
enum Constants {
    /// Network
    enum Repository {
        static let baseURL = "https://api.exponea.com/"
        static let contentType = "application/json"
        static let headerContentType = "Content-Type"
        static let headerAccept = "Accept"
        static let headerContentLenght = "Content-length"
    }
    /// Plist keys
    enum Keys {
        static let token = "exponeaProjectIdKey"
        static let launchedBefore = "launchedBefore"
    }
    /// SDK Info
    enum DeviceInfo {
        static let osName = "iOS"
        static let osVersion = UIDevice.current.systemVersion
        static let sdk = "iOS SDK"
        static let sdkVersion = "1.0.0"
        static let deviceModel = UIDevice.current.model
        static let deviceType = ""
    }
    enum EventTypes {
        static let installation = "installation"
    }
    enum ErrorMessages {
        static let tokenNotConfigured = "Project token is not configured. Please configure it before interact with the ExponeaSDK"
        static let sdkNotConfigured = "ExponeaSDK isn't configured."
    }
}
