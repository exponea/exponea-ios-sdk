//
//  ExponeaAppDelegate.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 20/05/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation

open class ExponeaAppDelegate: NSObject, UNUserNotificationCenterDelegate, UIApplicationDelegate {
    open func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Exponea.shared.handlePushNotificationToken(deviceToken: deviceToken)
    }

    open func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Exponea.shared.handlePushNotificationOpened(userInfo: userInfo)
        completionHandler(.newData)
    }

    open func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Exponea.shared.handlePushNotificationOpened(response: response)
        completionHandler()
    }
}
