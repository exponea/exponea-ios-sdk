//
//  PushNotificationManager.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 25/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import UserNotifications
import UIKit

public protocol PushNotificationManagerDelegate: AnyObject {

    func pushNotificationOpened(
        with action: ExponeaNotificationActionType,
        value: String?,
        extraData: [AnyHashable: Any]?
    )

    func silentPushNotificationReceived(extraData: [AnyHashable: Any]?)
}

public extension PushNotificationManagerDelegate {
    // default implementation is empty for compatibility
    func silentPushNotificationReceived(extraData: [AnyHashable: Any]?) {}
}

public struct PushTokenType {
    var pushToken: String
    var isTokenValid: Bool
}

final class PushNotificationManager: NSObject, PushNotificationManagerType {
    /// The tracking manager used to track push events
    internal var trackingConsentManager: TrackingConsentManagerType
    internal var trackingManager: TrackingManagerType

    private let requirePushAuthorization: Bool
    private let appGroup: String? // used for sharing data across extensions, fx. for push delivered tracking
    private let tokenTrackFrequency: TokenTrackFrequency
    private let urlOpener: UrlOpenerType
    private var currentPushToken: PushTokenType?
    private var lastKnownPushToken: PushTokenType?
    private var lastTokenTrackDate: Date
    private var pushNotificationSwizzler: PushNotificationSwizzler?

    // some push notification can be received before the delegate is set, we'll store them and call delegate once set
    internal var pendingOpenedPushes: [PushOpenedData] = []
    private weak var delegateValue: PushNotificationManagerDelegate?
    internal var delegate: PushNotificationManagerDelegate? {
        get {
            return delegateValue
        }
        set {
            delegateValue = newValue
            guard let delegateValue = delegateValue else {
                return
            }
            pendingOpenedPushes.forEach {
                if $0.silent {
                    delegateValue.silentPushNotificationReceived(extraData: $0.extraData)
                } else {
                    delegateValue.pushNotificationOpened(
                        with: $0.actionType,
                        value: $0.actionValue,
                        extraData: $0.extraData
                    )
                }
            }
            pendingOpenedPushes = []
        }
    }

    var didReceiveSelfPushCheck: Bool = false

    let decoder: JSONDecoder = JSONDecoder.snakeCase

    init(
        trackingConsentManager: TrackingConsentManagerType,
        trackingManager: TrackingManagerType,
        swizzlingEnabled: Bool,
        requirePushAuthorization: Bool,
        appGroup: String?,
        tokenTrackFrequency: TokenTrackFrequency,
        currentPushToken: String?,
        lastTokenTrackDate: Date?,
        urlOpener: UrlOpenerType
    ) {
        self.appGroup = appGroup
        self.trackingConsentManager = trackingConsentManager
        self.trackingManager = trackingManager
        self.tokenTrackFrequency = tokenTrackFrequency

        if let currentPushToken {
            let newToken = PushTokenType(
                pushToken: currentPushToken,
                isTokenValid: true
            )
            self.currentPushToken = newToken
            self.lastKnownPushToken = newToken
        }
        self.lastTokenTrackDate = lastTokenTrackDate ?? .distantPast
        self.urlOpener = urlOpener
        self.requirePushAuthorization = requirePushAuthorization
        super.init()

        if swizzlingEnabled {
            pushNotificationSwizzler = PushNotificationSwizzler(self)
            pushNotificationSwizzler?.addAutomaticPushTracking()
        }
        checkForDeliveredPushMessages()
        processStoredPushOpens()
        verifyPushStatusAndTrackPushToken()

        // We need to register for silent push notifications, but let's only do it when visible pushes are allowed
        // so we don't track push token to exponea without permission to show
        // push notifications unless enabled by developer in configuration
        if requirePushAuthorization {
            UNAuthorizationStatusProvider.current.isAuthorized { authorized in
                if authorized {
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        IntegrationManager.shared.onIntegrationStoppedCallbacks.append { [weak self] in
            guard let self else { return }
            self.pushNotificationSwizzler?.removeAutomaticPushTracking()
            NotificationCenter.default.removeObserver(
                self,
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )
        }
    }

    deinit {
        pushNotificationSwizzler?.removeAutomaticPushTracking()
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    // MARK: App lifecycle
    @objc internal func applicationDidBecomeActive() {
        Exponea.shared.executeSafely {
            self.applicationDidBecomeActiveUnsafe()
        }
    }

    // MARK: - Actions -

    func handlePushOpened(userInfoObject: AnyObject?, actionIdentifier: String?) {
        Exponea.shared.executeSafely {
            self.handlePushOpenedUnsafe(
                userInfoObject: userInfoObject,
                actionIdentifier: actionIdentifier,
                timestamp: Date().timeIntervalSince1970,
                considerConsent: true
            )
        }
    }

    func handlePushOpenedWithoutTrackingConsent(userInfoObject: AnyObject?, actionIdentifier: String?) {
        Exponea.shared.executeSafely {
            self.handlePushOpenedUnsafe(
                userInfoObject: userInfoObject,
                actionIdentifier: actionIdentifier,
                timestamp: Date().timeIntervalSince1970,
                considerConsent: false
            )
        }
    }

    func handlePushOpenedUnsafe(userInfoObject: AnyObject?,
                                actionIdentifier: String?,
                                timestamp: Double,
                                considerConsent: Bool) {
        guard let pushOpenedData = PushNotificationParser.parsePushOpened(
            userInfoObject: userInfoObject,
            actionIdentifier: actionIdentifier,
            timestamp: timestamp,
            considerConsent: considerConsent
        ) else {
            return
        }
        handlePushOpenedUnsafe(pushOpenedData: pushOpenedData)
    }

    func handlePushOpenedUnsafe(pushOpenedData: PushOpenedData) {
        if case .selfCheck = pushOpenedData.actionType {
            didReceiveSelfPushCheck = true
            return
        }
        trackingConsentManager.trackClickedPush(data: pushOpenedData)
        if pushOpenedData.silent {
            if let delegate = delegate {
                delegate.silentPushNotificationReceived(extraData: pushOpenedData.extraData)
            } else {
                pendingOpenedPushes.append(pushOpenedData)
            }
        } else {
            if pushOpenedData.considerConsent
                && !pushOpenedData.hasTrackingConsent
                && !GdprTracking.isTrackForced(pushOpenedData.actionValue)
             {
                Exponea.logger.log(.verbose, message: "Campaign data for delivered notification are not tracked because consent is not given")
            } else {
                // save campaign to be added to session start
                Exponea.shared.trackCampaignData(data: pushOpenedData.campaignData, timestamp: nil)
            }

            // Notify the delegate
            if let delegate = delegate {
                delegate.pushNotificationOpened(
                    with: pushOpenedData.actionType,
                    value: pushOpenedData.actionValue,
                    extraData: pushOpenedData.extraData
                )
            } else {
                pendingOpenedPushes.append(pushOpenedData)
            }

            switch pushOpenedData.actionType {
            case .none, .openApp, .selfCheck:
                // No need to do anything, app was opened automatically
                break

            case .browser:
                if let value = pushOpenedData.actionValue {
                    urlOpener.openBrowserLink(value)
                }

            case .deeplink:
                if let value = pushOpenedData.actionValue {
                    urlOpener.openDeeplink(value)
                }
            }
        }
    }

    func handlePushTokenRegistered(dataObject: AnyObject?) {
        guard let tokenData = dataObject as? Data else {
            return
        }
        Exponea.shared.executeSafely {
            self.handlePushTokenRegisteredUnsafe(token: tokenData.tokenString)
        }
    }

    func handlePushTokenRegistered(token: String) {
        Exponea.shared.executeSafely {
            self.handlePushTokenRegisteredUnsafe(token: token)
        }
    }

    private func handlePushTokenRegisteredUnsafe(token: String) {
        Exponea.shared.executeSafely {
            UNAuthorizationStatusProvider.current.isAuthorized { [weak self] authorized in
                guard let self else { return }
                Exponea.shared.executeSafely {
                    let pushTokenType = PushTokenType(
                        pushToken: token,
                        isTokenValid: !self.requirePushAuthorization || authorized
                    )
                    self.lastKnownPushToken = pushTokenType
                    self.currentPushToken = pushTokenType
                    self.trackCurrentPushToken(isAuthorized: authorized)
                }
            }
        }
    }

    static func storePushOpened(userInfoObject: AnyObject?,
                                actionIdentifier: String?,
                                timestamp: Double,
                                considerConsent: Bool) {
        guard let userDefaults = UserDefaults(suiteName: Constants.General.userDefaultsSuite),
              let pushOpenedData = PushNotificationParser.parsePushOpened(
                  userInfoObject: userInfoObject,
                  actionIdentifier: actionIdentifier,
                  timestamp: timestamp,
                  considerConsent: considerConsent
              ) else {
            return
        }
        if let serialized = pushOpenedData.serialize() {
            var opened = userDefaults.array(forKey: Constants.General.openedPushUserDefaultsKey) ?? []
            opened.append(serialized)
            userDefaults.set(opened, forKey: Constants.General.openedPushUserDefaultsKey)
        }
    }

    func processStoredPushOpens() {
        let userDefaults = UserDefaults(suiteName: Constants.General.userDefaultsSuite)
        guard let array = userDefaults?.array(forKey: Constants.General.openedPushUserDefaultsKey) else {
            Exponea.logger.log(.verbose, message: "No opened push to track present in UserDefaults.")
            return
        }

        guard let dataArray = array as? [Data] else {
            Exponea.logger.log(.warning, message: "Opened push data present in shared group but incorrect type.")
            return
        }

        for data in dataArray {
            guard let pushOpenedData = PushOpenedData.deserialize(from: data) else {
                Exponea.logger.log(.warning, message: "Cannot deserialize stored opened push data.")
                continue
            }
            Exponea.logger.log(.verbose, message: "Handling saved opened push notification.")
            handlePushOpenedUnsafe(pushOpenedData: pushOpenedData)
        }
        userDefaults?.removeObject(forKey: Constants.General.openedPushUserDefaultsKey)
    }

    internal func checkForDeliveredPushMessages() {
        guard let appGroup = appGroup else {
            Exponea.logger.log(.verbose, message: "No app group was setup, push delivered tracking is disabled.")
            return
        }
        guard let userDefaults = UserDefaults(suiteName: appGroup) else {
            Exponea.logger.log(.verbose, message: "Unable to load local storage of delivered push to track")
            return
        }
        trackDeliveredPushMessages(userDefaults)
        trackDeliveredPushEvents(userDefaults)
    }

    /// Loads received and stored Push notifications that were not tracked due to missing SDK configuration
    internal func trackDeliveredPushMessages(_ source: UserDefaults) {
        guard let array = source.array(forKey: Constants.General.deliveredPushUserDefaultsKey) else {
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
            trackingConsentManager.trackDeliveredPush(data: notification, mode: .CONSIDER_CONSENT)
        }
        // Clear after all is processed
        source.removeObject(forKey: Constants.General.deliveredPushUserDefaultsKey)
    }

    /// Uploads track events for delivered Push notifications that were not uploaded to backend because of some problem
    internal func trackDeliveredPushEvents(_ source: UserDefaults) {
        guard let array = source.array(forKey: Constants.General.deliveredPushEventUserDefaultsKey) else {
            Exponea.logger.log(.verbose, message: "No delivered push events to track in shared app group.")
            return
        }
        guard let dataArray = array as? [Data] else {
            Exponea.logger.log(.warning, message: "Delivered push events present in shared group but incorrect type.")
            return
        }
        // Process notification events
        for each in dataArray {
            guard let notificationEvent = EventTrackingObject.deserialize(from: each) else {
                Exponea.logger.log(.warning, message: "Cannot deserialize stored delivered push event")
                continue
            }
            trackingManager.trackDeliveredPushEvent(notificationEvent)
        }
        // Clear after all is processed
        source.removeObject(forKey: Constants.General.deliveredPushEventUserDefaultsKey)
    }

    func verifyPushStatusAndTrackPushToken() {
        UNAuthorizationStatusProvider.current.isAuthorized { authorized in
            if self.requirePushAuthorization && !authorized {
                if self.currentPushToken?.isTokenValid == true {
                    self.currentPushToken?.isTokenValid = false
                    self.trackCurrentPushToken(isAuthorized: authorized)
                }
            } else {
                self.currentPushToken?.isTokenValid = true
                self.checkForPushTokenFrequency(isAuthorized: authorized)
            }
        }
    }

    private func trackCurrentPushToken(isAuthorized: Bool) {
        guard !IntegrationManager.shared.isStopped else {
            Exponea.logger.log(.error, message: "trackCurrentPushToken failed, Exponea is stopped")
            return
        }
        do {
            try trackingManager.trackNotificationState(
                pushToken: currentPushToken?.pushToken,
                isValid: currentPushToken?.isTokenValid ?? true,
                description: !requirePushAuthorization
                ? "Permission not required" : (
                    isAuthorized
                    ? "Permission granted"
                    : "Permission denied"
                )
            )
        } catch {
            Exponea.logger.log(.error, message: "Error tracking current push token. \(error.localizedDescription)")
        }
    }

    private func checkForPushTokenFrequency(isAuthorized authorized: Bool) {
        switch tokenTrackFrequency {
        case .everyLaunch:
            // Track push token
            lastTokenTrackDate = .init()
            trackCurrentPushToken(isAuthorized: authorized)

        case .daily:
            // Compare last track dates, if equal or more than a day, track
            let now = Date()
            if abs(lastTokenTrackDate.timeIntervalSince(now)) >= 60 * 60 * 24 {
                lastTokenTrackDate = now
                trackCurrentPushToken(isAuthorized: authorized)
            }

        case .onTokenChange:
            // Track if changed from last tracked
            if trackingManager.customerPushToken != currentPushToken?.pushToken {
                lastTokenTrackDate = .init()
                trackCurrentPushToken(isAuthorized: authorized)
            }
        }
    }
}

extension PushNotificationManager {
    func applicationDidBecomeActiveUnsafe() {
        checkForDeliveredPushMessages()
        // we don't have to check for opened pushes here, Exponea SDK was initialized so it will be tracked directly
        verifyPushStatusAndTrackPushToken()
    }
}
