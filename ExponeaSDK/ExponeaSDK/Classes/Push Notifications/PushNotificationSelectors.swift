//
//  PushNotificationSelectors.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 25/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import UserNotifications
import UIKit

internal enum PushSelectorMapping {
    internal typealias Mapping = (original: Selector, swizzled: Selector)

    internal enum Original {
        static let registration = #selector(
            UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:)
        )

        static let centerDelegateReceive = NSSelectorFromString(
            "userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:"
        )

        static let applicationReceive = NSSelectorFromString(
            "application:didReceiveRemoteNotification:fetchCompletionHandler:"
        )
    }

    internal enum Swizzled {
        static let registration = #selector(
            UIResponder.exponeaApplicationSwizzle(_:didRegisterPushToken:)
        )

        static let centerDelegateReceive = #selector(
            NSObject.exponeaUserNotificationCenter(_:newDidReceive:withCompletionHandler:)
        )

        static let applicationReceive = #selector(
            UIResponder.exponeaApplication(_:newDidReceiveRemoteNotification:fetchCompletionHandler:)
        )
    }

    internal enum Signatures {
        static let registration = (@convention(c) (
            AnyObject, Selector, UIApplication, Data) -> Void).self
        static let centerDelegateReceive = (@convention(c) (
            AnyObject, Selector, UNUserNotificationCenter, UNNotificationResponse, @escaping () -> Void) -> Void).self
        static let applicationReceive = (@convention(c)
            (AnyObject, Selector, UIApplication, NSDictionary, @escaping (UIBackgroundFetchResult) -> Void)
            -> Void).self
    }

    internal static let registration: Mapping
        = (Original.registration, Swizzled.registration)
    internal static let centerDelegateReceive: Mapping
        = (Original.centerDelegateReceive, Swizzled.centerDelegateReceive)
    internal static let applicationReceive: Mapping
        = (Original.applicationReceive, Swizzled.applicationReceive)
}
