//
//  NotificationViewController.swift
//  ExampleNotificationContent
//
//  Created by Dominik Hadl on 06/12/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI
import ExponeaSDKNotifications

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    let exponeaService = ExponeaNotificationContentService()

    func didReceive(_ notification: UNNotification) {
        exponeaService.didReceive(notification, context: extensionContext, viewController: self)
    }
}
