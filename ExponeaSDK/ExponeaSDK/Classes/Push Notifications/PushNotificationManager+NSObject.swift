//
//  PushNotificationManager+NSObject.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 11/10/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import UserNotifications

extension NSObject {
    @objc func userNotificationCenter(_ center: UNUserNotificationCenter,
                                      newDidReceive response: UNNotificationResponse,
                                      withCompletionHandler completionHandler: @escaping () -> Void) {
        let selector = PushSelectorMapping.newReceive.original

        guard let originalMethod = class_getInstanceMethod(type(of: self), selector),
            let swizzle = Swizzler.swizzles[originalMethod] else {
                return
        }

        let curriedImplementation = unsafeBitCast(swizzle.originalMethod,
                                                  to: PushSelectorMapping.Signatures.newReceive)
        curriedImplementation(self, selector, center, response, completionHandler)

        for (_, block) in swizzle.blocks {
            block(center as AnyObject?,
                  response.notification.request.content.userInfo as AnyObject?,
                  response.actionIdentifier as AnyObject?)
        }
    }
}
