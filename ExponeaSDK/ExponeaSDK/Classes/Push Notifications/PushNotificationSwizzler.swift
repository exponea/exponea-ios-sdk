//
//  PushNotificationSwizzler.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 07/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation
import UserNotifications

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
    private var pushOpenedSwizzleToken: String = UUID().uuidString

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
    /// There are 3 ways to register for remove notifications:
    /// 1. UNUserNotificationCenter.delegate
    /// 2. UIApplication.application(_, didReceiveRemoteNotification , fetchCompletionHandler:)
    /// 3. UIApplication.application(_, didReceiveRemoteNotification: )
    ///
    /// They work as fallbacks, system tries the first, only if there's no delegate second
    /// and if second is not implemented calls third.
    /// Keep this in mind.
    ///
    /// This method works in the following way:
    ///
    /// 1. It **always** observes changes to `UNUserNotificationCenter`'s `delegate` property and on changes
    /// it calls `notificationsDelegateChanged(_:)`.
    /// 2. Checks if we there is already an existing `UNUserNotificationCenter` delegate,
    /// if so, calls `swizzleUserNotificationsDidReceive(on:)` and exits.
    /// 3. If step 2. fails, it continues to check if the host AppDelegate implements either one of the supported
    /// didReceiveNotification methods. If so, swizzles the one that's implemented while preferring the variant
    /// with fetch handler as that is what Apple recommends.
    /// 4. If step 3 fails, it creates a dummy object `PushNotificationReceiver` that implements the
    /// `UNUserNotificationCenterDelegate` protocol, sets it as the delegate for `UNUserNotificationCenter` and lastly
    /// swizzles the implementation with the custom one in change observer.
    private func swizzleNotificationReceived() {
        guard let appDelegate = uiApplicationDelegating.delegate else {
            Exponea.logger.log(.error, message: "Critical error, no app delegate class available.")
            return
        }

        let appDelegateClass: AnyClass = type(of: appDelegate)
        var swizzleMapping: PushSelectorMapping.Mapping?

        // Add observer
        observer = PushNotificationDelegateObserver(
            observable: unUserNotificationCenterDelegating,
            callback: notificationsDelegateChanged
        )

        // Check for UNUserNotification's delegate did receive remote notification, if it is setup
        // prefer using that over the UIAppDelegate functions.
        if let delegate = unUserNotificationCenterDelegating.delegate {
            swizzleUserNotificationsDidReceive(on: type(of: delegate))
            return
        }

        // Check if UIAppDelegate notification receive functions are implemented
        if class_getInstanceMethod(appDelegateClass, PushSelectorMapping.handlerReceive.original) != nil {
            // Check for UIAppDelegate's did receive remote notification with fetch completion handler (preferred)
            swizzleMapping = PushSelectorMapping.handlerReceive
        } else if class_getInstanceMethod(appDelegateClass, PushSelectorMapping.deprecatedReceive.original) != nil {
            // Check for UIAppDelegate's deprecated receive remote notification
            swizzleMapping = PushSelectorMapping.deprecatedReceive
        }

        // If user is overriding either of UIAppDelegete receive functions, swizzle it
        if let mapping = swizzleMapping {
            // Do the swizzling
            let token = UUID().uuidString
            pushOpenedSwizzleToken = token
            Swizzler.swizzleSelector(mapping.original,
                                     with: mapping.swizzled,
                                     for: appDelegateClass,
                                     name: "NotificationOpened",
                                     block: { [weak self] (_, userInfoObject, _) in
                                        guard self?.pushOpenedSwizzleToken == token else {
                                            return
                                        }
                                        self?.pushNotificationManager?.handlePushOpened(
                                            userInfoObject: userInfoObject,
                                            actionIdentifier: nil
                                        )
                                     },
                                     addingMethodIfNecessary: true)
        } else {
            // The user is not overriding any UIAppDelegate receive functions nor is using UNUserNotificationCenter.
            // Because we don't have a delegate for UNUserNotifications, let's make a dummy one and set it
            // as the delegate, until the user creates their own delegate (handled by observing .
            receiver = PushNotificationReceiver()
            unUserNotificationCenterDelegating.delegate = receiver
        }
    }

    /// Monitor changes in the `UNUserNotificationCenter` delegate.
    ///
    /// - Parameter change: The KVO change object containing the old and new values.
    private func notificationsDelegateChanged(_ change: NSKeyValueObservedChange<UNUserNotificationCenterDelegate?>) {
        if change.newValue == nil {
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
        pushOpenedSwizzleToken = token
        // Swizzle the notification delegate notification received function
        Swizzler.swizzleSelector(PushSelectorMapping.newReceive.original,
                                 with: PushSelectorMapping.newReceive.swizzled,
                                 for: delegateClass,
                                 name: "NotificationOpened",
                                 block: { [weak self] (_, userInfoObject, actionIdentifier) in
                                    guard self?.pushOpenedSwizzleToken == token else {
                                        return
                                    }
                                    self?.pushNotificationManager?.handlePushOpened(userInfoObject: userInfoObject,
                                                           actionIdentifier: actionIdentifier as? String)
                                 },
                                 addingMethodIfNecessary: true)
    }
}
