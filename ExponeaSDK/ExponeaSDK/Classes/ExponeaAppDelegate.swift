//
//  ExponeaAppDelegate.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 20/05/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation
import UIKit

open class ExponeaAppDelegate: NSObject, UNUserNotificationCenterDelegate, UIApplicationDelegate {
    /// When the application is started by opening a push notification we need to get if from launch options.
    /// When you override this method, don't forget to call
    /// super.application(application, didFinishLaunchingWithOptions: launchOptions)
    @discardableResult
    open func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // process push notification from launch options - when app is not running while push is received
        if let launchOptions = launchOptions,
           let userInfo = launchOptions[UIApplication.LaunchOptionsKey.remoteNotification] as? [AnyHashable: Any] {
            Exponea.shared.handlePushNotificationOpened(userInfo: userInfo)
        }
        UNUserNotificationCenter.current().delegate = self
        return true
    }

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
