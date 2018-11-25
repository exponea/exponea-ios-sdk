//
//  Exponea+PushNotifications.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 25/11/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import UserNotifications

extension Exponea {
    public func createNotificationCategories(openAppButtonTitle: String,
                                               openBrowserButtonTitle: String,
                                               openDeeplinkButtonTitle: String) -> Set<UNNotificationCategory> {
        return PushNotificationManager.createNotificationCategories(openAppButtonTitle: openAppButtonTitle,
                                                                    openBrowserButtonTitle: openBrowserButtonTitle,
                                                                    openDeeplinkButtonTitle: openDeeplinkButtonTitle)
    }
}
