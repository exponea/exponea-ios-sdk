//
//  PushNotificationSwizzler.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 07/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation
import UserNotifications
import UIKit

/**
 In order to unit test swizzling of methods related to receiving push notification,
 we have to solve issue of missing UNUserNotificationCenter and inability to set UIApplication.delegate.
 Instead of using UIApplication and UNUserNotificationCenter directly, we'll
 work with protocols that have delegates we need.
 In unit tests we can pass different object that conform to those protocols.
 */
final class PushNotificationSwizzler {
    private let uiApplicationDelegating: UIApplicationDelegating
    private let unUserNotificationCenterDelegating: UNUserNotificationCenterDelegating

    private var receiver: PushNotificationReceiver?
    private var observer: PushNotificationDelegateObserver?
    private weak var pushNotificationManager: PushNotificationManagerType?

    /*
     We should always swizzle notification delegate to make sure it gets called if developer/sdk changes it.
     But if the developer/sdk swizzles/changes the delegate and calls
     the original method we would get called multiple times.
     Let's keep a unique token that we change with every swizzle
     */
    private var pushOpenedApplicationSwizzleToken: String = UUID().uuidString
    private var pushOpenedCenterSwizzleToken: String = UUID().uuidString

    public init(
        _ manager: PushNotificationManagerType,
        uiApplicationDelegating: UIApplicationDelegating? = nil,
        unUserNotificationCenterDelegating: UNUserNotificationCenterDelegating? = nil
    ) {
        self.pushNotificationManager = manager
        self.uiApplicationDelegating = uiApplicationDelegating ?? UIApplication.shared
        if Exponea.isBeingTested {
            self.unUserNotificationCenterDelegating
                = unUserNotificationCenterDelegating ?? BasicUNUserNotificationCenterDelegating()
        } else {
            self.unUserNotificationCenterDelegating
                = unUserNotificationCenterDelegating ?? UNUserNotificationCenter.current()
        }
    }

    func addAutomaticPushTracking() {
        swizzleTokenRegistrationTracking()
        swizzleNotificationReceived()
    }

    func removeAutomaticPushTracking() {
        observer = nil
        receiver = nil

        for swizzle in Swizzler.swizzles {
            Swizzler.unswizzle(swizzle.value)
        }
    }

    /// This functions swizzles the token registration method to intercept the token and submit it to Exponea.
    private func swizzleTokenRegistrationTracking() {
        guard let appDelegate = uiApplicationDelegating.delegate else {
            return
        }

        // Monitor push registration
        Swizzler.swizzleSelector(PushSelectorMapping.registration.original,
                                 with: PushSelectorMapping.registration.swizzled,
                                 for: type(of: appDelegate),
                                 name: "PushTokenRegistration",
                                 block: { [weak self] (_, dataObject, _) in
                                    self?.pushNotificationManager?.handlePushTokenRegistered(dataObject: dataObject) },
                                 addingMethodIfNecessary: true)
    }

    /// Swizzles the appropriate 'notification received' method to interecept received notifications and then calls
    /// the `handlePushOpened` function with the payload so that the event can be tracked to Exponea.
    ///
    /// There are 3 ways to receive remote notifications:
    /// 1. UNUserNotificationCenter.delegate
    /// 2. UIApplication.application(_, didReceiveRemoteNotification , fetchCompletionHandler:)
    /// 3. UIApplication.application(_, didReceiveRemoteNotification: ) (deprecated in iOS 10 and no longer supported)
    ///
    /// When app is closed and push notification is clicked, 1. is used and delegate is called.
    /// Otherwise(app is opened/push is silent) 2. is called.
    ///
    /// This method works in the following way:
    ///
    /// 1. It **always** observes changes to `UNUserNotificationCenter`'s `delegate` property and on changes
    /// it calls `notificationsDelegateChanged(_:)`.
    /// 2. Checks if we there is already an existing `UNUserNotificationCenter` delegate,
    /// if so, calls `swizzleUserNotificationsDidReceive(on:)`, otherwise adds new empty delegate to be swizzled.
    /// 3. We need to implement `application:didReceiveRemoteNotification:fetchCompletionHandler:`.
    /// We either swizzle existing method, of create a new one.
    private func swizzleNotificationReceived() {
        guard let appDelegate = uiApplicationDelegating.delegate else {
            Exponea.logger.log(.error, message: "Critical error, no app delegate class available.")
            return
        }

        let appDelegateClass: AnyClass = type(of: appDelegate)

        // Add observer
        observer = PushNotificationDelegateObserver(
            observable: unUserNotificationCenterDelegating,
            callback: notificationsDelegateChanged
        )

        // Check for UNUserNotification's delegate did receive remote notification.
        // If it is setup swizzle it, otherwise add empty delegate and let observer swizzle it.
        if let delegate = unUserNotificationCenterDelegating.delegate {
            swizzleUserNotificationsDidReceive(on: type(of: delegate))
        } else {
            receiver = PushNotificationReceiver()
            unUserNotificationCenterDelegating.delegate = receiver
        }

        // Swizzle application's `didReceiveRemoteNotification` method, or add it if it doesn't exist.
        let token = UUID().uuidString
        pushOpenedApplicationSwizzleToken = token
        Swizzler.swizzleSelector(
            PushSelectorMapping.applicationReceive.original,
            with: PushSelectorMapping.applicationReceive.swizzled,
            for: appDelegateClass,
            name: "NotificationOpened",
            block: { [weak self] (_, userInfoObject, _) in
                guard self?.pushOpenedApplicationSwizzleToken == token else {
                    return
                }
                self?.pushNotificationManager?.handlePushOpened(
                    userInfoObject: userInfoObject,
                    actionIdentifier: nil
                )
            },
            addingMethodIfNecessary: true
        )
    }

    /// Monitor changes in the `UNUserNotificationCenter` delegate.
    ///
    /// - Parameter change: The KVO change object containing the old and new values.
    private func notificationsDelegateChanged(_ change: NSKeyValueObservedChange<UNUserNotificationCenterDelegate?>) {
        if change.newValue ?? nil == nil {
            receiver = PushNotificationReceiver()
            unUserNotificationCenterDelegating.delegate = receiver
        }
        guard let delegate = unUserNotificationCenterDelegating.delegate else {
            return
        }
        swizzleUserNotificationsDidReceive(on: type(of: delegate))
    }

    private func swizzleUserNotificationsDidReceive(on delegateClass: AnyClass) {
        let token = UUID().uuidString
        pushOpenedCenterSwizzleToken = token
        // Swizzle the notification delegate notification received function
        Swizzler.swizzleSelector(PushSelectorMapping.centerDelegateReceive.original,
                                 with: PushSelectorMapping.centerDelegateReceive.swizzled,
                                 for: delegateClass,
                                 name: "NotificationOpened",
                                 block: { [weak self] (_, userInfoObject, actionIdentifier) in
                                    guard self?.pushOpenedCenterSwizzleToken == token else {
                                        return
                                    }
                                    self?.pushNotificationManager?.handlePushOpened(userInfoObject: userInfoObject,
                                                           actionIdentifier: actionIdentifier as? String)
                                 },
                                 addingMethodIfNecessary: true)
    }
}
