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

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        guard let content = (request.content.mutableCopy() as? UNMutableNotificationContent) else {
            return
        }

        //temporary modify notification data
        var new = [String: Any]()
        new["sent_timestamp"] = 1618472942.259
        new["type"] = "push"
        var attributes = [String: Any]()
        attributes["attributes"] = new
        content.userInfo.merge(attributes) { (_, new) in new }

        let updatedRequest = UNNotificationRequest(identifier: request.identifier, content: content, trigger: request.trigger)

        exponeaService.process(request: updatedRequest, contentHandler: contentHandler)
    }

    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise
    // the original push payload will be used.
    override func serviceExtensionTimeWillExpire() {
        exponeaService.serviceExtensionTimeWillExpire()
    }
}
