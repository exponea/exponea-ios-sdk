//
//  NotificationService.swift
//  ExampleNotificationService
//
//  Created by Dominik Hadl on 22/11/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import UserNotifications
import ExponeaSDKNotifications

class NotificationService: UNNotificationServiceExtension {

    let exponeaService = ExponeaNotificationService(appGroup: "group.com.exponea.ExponeaSDK-Example2")

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        exponeaService.process(request: request, contentHandler: contentHandler)
    }

    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
    override func serviceExtensionTimeWillExpire() {
        exponeaService.serviceExtensionTimeWillExpire()
    }
}
