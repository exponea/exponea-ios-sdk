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
    /// Keys for plist files and userdefaults
    enum Keys {
        static let token = "exponeaProjectIdKey"
        static let launchedBefore = "launchedBefore"
        static let sessionStarted = "sessionStarted"
        static let sessionEnded = "sessionEnded"
        static let timeout = "sessionTimeout"
        static let autoSessionTrack = "automaticSessionTrack"
        static let appVersion = "CFBundleShortVersionString"
    }
    /// SDK Info
    enum DeviceInfo {
        static let osName = "iOS"
        static let osVersion = UIDevice.current.systemVersion
        static let sdk = "iOS SDK"
        static let sdkVersion = "1.0.0"
        static let deviceModel = UIDevice.current.model
    }
    /// Type of customer events
    enum EventTypes {
        static let installation = "installation"
        static let sessionEnd = "session_end"
        static let sessionStart = "session_start"
        static let payment = "payment"
    }
    /// Error messages
    enum ErrorMessages {
        static let tokenNotConfigured = "Project token is not configured. Please configure it before interact with the ExponeaSDK"
        static let sdkNotConfigured = "ExponeaSDK isn't configured."
        static let couldNotStartSession = "Could not start new session. Please verify the error log for more information"
        static let couldNotEndSession = "Could not end session. Please verify the error log for more information"
        static let couldNotTrackPayment = "The payment could not be tracked."
        static let verifyLogError = "Please verify the error log for more information."
    }
    /// Success messages
    enum SuccessMessages {
        static let sessionStarted = "Session succesfully started"
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
