//
//  Constants.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 05/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// enum with constants used through the SDK
public enum Constants {
    /// Network
    public enum Repository {
        public static let baseUrl = "https://api.exponea.com"
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
        static let installTracked = "installTracked"
        static let sessionStarted = "sessionStarted"
        static let sessionEnded = "sessionEnded"
        static let sessionBackgrounded = "sessionBackgrounded"
        static let timeout = "sessionTimeout"
        static let autoSessionTrack = "automaticSessionTrack"
        static let appVersion = "CFBundleShortVersionString"
        static let baseUrl = "exponeaBaseURL"
    }

    /// SDK Info
    enum DeviceInfo {
        static let osName = "iOS"
        static let osVersion = UIDevice.current.systemVersion
        static let sdk = "Exponea iOS SDK"
        static let deviceModel = UIDevice.current.model
    }

    /// Type of customer events
    enum EventTypes {
        static let installation = "installation"
        static let sessionEnd = "session_end"
        static let sessionStart = "session_start"
        static let payment = "payment"
        static let pushOpen = "campaign"
        static let pushDelivered = "campaign"
        static let campaignClick = "campaign_click"
        static let banner = "banner"
    }

    /// Error messages
    enum ErrorMessages {
        static let sdkNotConfigured = "Exponea SDK isn't configured. " +
            "Before any calls to SDK functions, please configure the SDK " +
            "with Exponea.shared.config() according to the documentation " +
            "https://github.com/exponea/exponea-ios-sdk/blob/develop/Documentation/CONFIG.md#configuring-the-sdk"
    }

    /// Success messages
    enum SuccessMessages {
        static let sessionStart = "Session succesfully started"
        static let sessionEnd = "Session succesfully ended"
        static let paymentDone = "Payment was succesfully tracked!"
    }

    /// Default session values represented in seconds
    public enum Session {
        public static let defaultTimeout = 6.0
        public static let maxRetries = 5
        static let sessionUpdateThreshold = 3.0
    }

    enum Tracking {
        // To be able to amend session tracking with campaign data, we have to delay immediate event flushing a bit
        static let immediateFlushDelay = 3.0
    }

    /// General constants
    enum General {
        static let iTunesStore = "iTunes Store"
        static let userDefaultsSuite = "ExponeaSDK"
        static let deliveredPushUserDefaultsKey = "EXPONEA_DELIVERED_PUSH_TRACKING"
        static let savedCampaignClickEvent = "EXPONEA_SAVED_CAMPAIGN_CLICK"
        static let inAppMessageDisplayStatusUserDefaultsKey = "EXPONEA_IN_APP_MESSAGE_DISPLAY_STATUS"
    }
}
