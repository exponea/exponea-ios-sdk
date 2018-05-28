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
        static let baseURL = "https://api.exponea.com"
        static let contentType = "application/json"
        static let headerContentType = "content-type"
        static let headerAccept = "accept"
        static let headerContentLenght = "content-length"
        static let headerAuthorization = "authorization"
    }

    /// Keys for plist files and userdefaults
    enum Keys {
        static let token = "exponeaProjectIdKey"
        static let authorization = "exponeaAuthorization"
        static let launchedBefore = "launchedBefore"
        static let sessionStarted = "sessionStarted"
        static let sessionEnded = "sessionEnded"
        static let timeout = "sessionTimeout"
        static let autoSessionTrack = "automaticSessionTrack"
        static let appVersion = "CFBundleShortVersionString"
        static let baseURL = "exponeaBaseURL"
    }

    /// SDK Info
    enum DeviceInfo {
        static let osName = "iOS"
        static let osVersion = UIDevice.current.systemVersion
        static let sdk = "Exponea iOS SDK"
        static let deviceModel = UIDevice.current.model
        static let sdkVersion: String = {
            let bundle = Bundle(for: Exponea.self)
            let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String
            return version ?? "Unknown version"
        }()
    }

    /// Type of customer events
    enum EventTypes {
        static let installation = "installation"
        static let sessionEnd = "session_end"
        static let sessionStart = "session_start"
        static let payment = "payment"
        static let pushOpen = "push_open"
    }

    /// Error messages
    enum ErrorMessages {
        static let sdkNotConfigured = "ExponeaSDK isn't configured."
    }

    /// Success messages
    enum SuccessMessages {
        static let sessionStart = "Session succesfully started"
        static let sessionEnd = "Session succesfully ended"
        static let paymentDone = "Payment was succesfully tracked!"
    }

    /// Default session values
    enum Session {
        static let defaultTimeout = 6.0
    }

    /// General constants
    enum General {
        static let iTunesStore = "iTunes Store"
    }
}
