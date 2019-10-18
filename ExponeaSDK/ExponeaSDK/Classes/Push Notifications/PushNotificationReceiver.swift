//
//  PushNotificationReceiver.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 11/10/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import UserNotifications

/// PushNotificationReceiver is a dummy object used as a temporary delegate, should the UNUserNotificationCenter
/// have no delegate assigned at the time when Exponea SDK is initialised and should the automatic push tracking
/// be enabled. In it's deafult implementation it just calls the completion handler, which is the only required
/// action that this function has to do, according to UserNotifications framework documentation.
class PushNotificationReceiver: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        // The completion handler has to be called
        completionHandler()
    }
}
