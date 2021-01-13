//
//  PushNotificationManager+UIResponder.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 11/10/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import UIKit

extension UIResponder {
    @objc func exponeaApplication(
        _ application: UIApplication,
        newDidReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // Get the swizzle
        let selector = PushSelectorMapping.applicationReceive.original
        guard let originalMethod = class_getInstanceMethod(type(of: self), selector),
            let swizzle = Swizzler.swizzles[originalMethod] else {
                return
        }

        // Perform the original implementation first
        let curriedImplementation = unsafeBitCast(swizzle.originalMethod,
                                                  to: PushSelectorMapping.Signatures.applicationReceive)
        curriedImplementation(self, selector, application, userInfo as NSDictionary, completionHandler)

        // Now call our own implementations
        for (_, block) in swizzle.blocks {
            block(application as AnyObject?, userInfo as AnyObject?, nil)
        }
    }

    @objc func exponeaApplicationSwizzle(_ application: UIApplication, didRegisterPushToken deviceToken: Data) {
        // Get the swizzle
        let selector = PushSelectorMapping.registration.original
        guard let originalMethod = class_getInstanceMethod(type(of: self), selector),
            let swizzle = Swizzler.swizzles[originalMethod] else {
                return
        }

        // Perform the original implementation first
        let curriedImplementation = unsafeBitCast(swizzle.originalMethod,
                                                  to: PushSelectorMapping.Signatures.registration)
        curriedImplementation(self, selector, application, deviceToken)

        // Now call our own implementations
        for (_, block) in swizzle.blocks {
            block(application as AnyObject?, deviceToken as AnyObject?, nil)
        }
    }
}
