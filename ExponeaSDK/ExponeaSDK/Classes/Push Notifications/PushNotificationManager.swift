//
//  PushNotificationManager.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 25/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import UserNotifications

public protocol PushNotificationManagerDelegate: class {
    func pushNotificationOpened(with action: ExponeaNotificationActionType,
                                value: String?, extraData: [AnyHashable: Any]?)
}

class PushNotificationManager: NSObject, PushNotificationManagerType {
    /// The tracking manager used to track push events
    internal weak var trackingManager: TrackingManagerType?

    private let appGroup: String? // used for sharing data across extensions, fx. for push delivered tracking
    private let tokenTrackFrequency: TokenTrackFrequency
    private var currentPushToken: String?
    private var lastTokenTrackDate: Date
    lazy var pushNotificationSwizzler = PushNotificationSwizzler(self)

    internal weak var delegate: PushNotificationManagerDelegate?

    let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    init(trackingManager: TrackingManagerType,
         appGroup: String?,
         tokenTrackFrequency: TokenTrackFrequency,
         currentPushToken: String?,
         lastTokenTrackDate: Date?) {
        self.appGroup = appGroup
        self.trackingManager = trackingManager
        self.tokenTrackFrequency = tokenTrackFrequency
        self.currentPushToken = currentPushToken
        self.lastTokenTrackDate = lastTokenTrackDate ?? .distantPast
        super.init()

        pushNotificationSwizzler.addAutomaticPushTracking()
        checkForDeliveredPushMessages()
        checkForPushTokenFrequency()
    }

    deinit {
        pushNotificationSwizzler.removeAutomaticPushTracking()
    }

    // MARK: - Actions -

    func handlePushOpened(userInfoObject: AnyObject?, actionIdentifier: String?) {
        Exponea.shared.executeSafely {
            handlePushOpenedUnsafe(userInfoObject: userInfoObject, actionIdentifier: actionIdentifier)
        }
    }

    func handlePushOpenedUnsafe(userInfoObject: AnyObject?, actionIdentifier: String?) {
        guard let pushOpenedData = PushNotificationParser.parsePushOpened(
            userInfoObject: userInfoObject,
            actionIdentifier: actionIdentifier
        ) else {
            return
        }

        var postAction: (() -> Void)?

        switch pushOpenedData.actionType {
        case .none, .openApp:
            // No need to do anything, app was opened automatically
            break

        case .browser, .deeplink:
            // Open the deeplink, iOS will handle if deeplink to safari/other apps
            if let value = pushOpenedData.actionValue, let url = URL(string: value) {
                // Create an action to be executed after tracking
                postAction = {
                    let application = UIApplication.shared

                    let openDeeplink = {
                        application.open(url, options: [:], completionHandler: { success in
                            // If no success opening url using shared app,
                            // try opening using current app
                            if !success {
                                _ = application.delegate?.application?(
                                    application,
                                    open: url,
                                    options: [:])
                            }
                        })
                    }

                    // Validate this is a valid URL, prevents NSUserActivity crash with invalid URL
                    // only http/https is allowed https://developer.apple.com/documentation/foundation/nsuseractivity/1418086-webpageurl
                    // eg. MYDEEPLINK::HOME:SCREEN:1, exponea://deeplink
                    guard url.absoluteString.isValidURL, url.scheme == "http" || url.scheme == "https" else {
                        openDeeplink()
                        return
                    }

                    // Simulate universal link user activity
                    let userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
                    userActivity.webpageURL = url

                    // Try and open the link as universal link first
                    let success = application.delegate?.application?(
                        application,
                        continue: userActivity,
                        restorationHandler: { _ in }
                    ) ?? false

                    // If universal links failed to open, let application handle the URL open
                    if !success {
                        openDeeplink()
                    }
                }
            }
        }

        // Track the event
        do {
            try trackingManager?.track(pushOpenedData.eventType, with: pushOpenedData.eventData)
        } catch {
            Exponea.logger.log(.error, message: "Error tracking push opened: \(error.localizedDescription)")
        }

        // Notify the delegate
        delegate?.pushNotificationOpened(
            with: pushOpenedData.actionType,
            value: pushOpenedData.actionValue,
            extraData: pushOpenedData.extraData
        )

        // If we have post process action, execute it
        postAction?()
    }

    func handlePushTokenRegistered(dataObject: AnyObject?) {
        Exponea.shared.executeSafely {
            handlePushTokenRegisteredUnsafe(dataObject: dataObject)
        }
    }

    func handlePushTokenRegisteredUnsafe(dataObject: AnyObject?) {
        guard let tokenData = dataObject as? Data else {
            return
        }

        // Update current push token
        currentPushToken = tokenData.tokenString

        do {
            let data = [DataType.pushNotificationToken(currentPushToken)]
            try trackingManager?.track(.registerPushToken, with: data)
        } catch {
            Exponea.logger.log(.error, message: "Error logging push token. \(error.localizedDescription)")
        }
    }

    internal func checkForDeliveredPushMessages() {
        guard let appGroup = appGroup else {
            Exponea.logger.log(.verbose, message: "No app group was setup, push delivered tracking is disabled.")
            return
        }

        let userDefaults = UserDefaults(suiteName: appGroup)
        guard let array = userDefaults?.array(forKey: Constants.General.deliveredPushUserDefaultsKey) else {
            Exponea.logger.log(.verbose, message: "No delivered push to track present in shared app group.")
            return
        }

        guard let dataArray = array as? [Data] else {
            Exponea.logger.log(.warning, message: "Delivered push data present in shared group but incorrect type.")
            return
        }

        // Process notifications
        for data in dataArray {
            guard let notification = NotificationData.deserialize(from: data) else {
                Exponea.logger.log(.warning, message: "Cannot deserialize stored delivered push data.")
                continue
            }

            // Create payload
            var properties: [String: JSONValue] = notification.properties
            properties["status"] = .string("delivered")

            // Track the event
            do {
                if let customEventType = notification.eventType,
                   !customEventType.isEmpty,
                   customEventType != Constants.EventTypes.pushDelivered {
                    try trackingManager?.track(
                        .customEvent,
                        with: [.eventType(customEventType), .properties(properties), .timestamp(notification.timestamp.timeIntervalSince1970)]
                    )
                } else {
                    try trackingManager?.track(
                        .pushDelivered,
                        with: [.properties(properties), .timestamp(notification.timestamp.timeIntervalSince1970)]
                    )
                }
            } catch {
                Exponea.logger.log(.error, message: "Error tracking push opened: \(error.localizedDescription)")
            }
        }

        // Clear after all is processed
        userDefaults?.removeObject(forKey: Constants.General.deliveredPushUserDefaultsKey)
    }

    func checkForPushTokenFrequency() {
        func trackPushToken() {
            do {
                let data = [DataType.pushNotificationToken(currentPushToken)]
                try trackingManager?.track(.registerPushToken, with: data)
            } catch {
                Exponea.logger.log(.error, message: "Error logging push token. \(error.localizedDescription)")
            }
        }

        switch tokenTrackFrequency {
        case .everyLaunch:
            // Track push token
            lastTokenTrackDate = .init()
            trackPushToken()

        case .daily:
            // Compare last track dates, if equal or more than a day, track
            let now = Date()
            if lastTokenTrackDate.timeIntervalSince(now) >= 86400 {
                lastTokenTrackDate = now
                trackPushToken()
            }

        case .onTokenChange:
            // nothing to do
            break
        }
    }
}

extension PushNotificationManager {
    func applicationDidBecomeActive() {
        checkForDeliveredPushMessages()
        checkForPushTokenFrequency()
    }
}
