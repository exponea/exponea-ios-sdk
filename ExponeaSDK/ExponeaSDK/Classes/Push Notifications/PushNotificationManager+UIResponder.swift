//
//  PushNotificationManager+UIResponder.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 11/10/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

extension UIResponder {
    @objc func application(_ application: UIApplication,
                           newDidReceiveRemoteNotification userInfo: [AnyHashable: Any],
                           fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Get the swizzle
        let selector = PushSelectorMapping.handlerReceive.original
        guard let originalMethod = class_getInstanceMethod(type(of: self), selector),
            let swizzle = Swizzler.swizzles[originalMethod] else {
                return
        }

        // Perform the original implementation first
        let curriedImplementation = unsafeBitCast(swizzle.originalMethod,
                                                  to: PushSelectorMapping.Signatures.handlerReceive)
        curriedImplementation(self, selector, application, userInfo as NSDictionary, completionHandler)

        // Now call our own implementations
        for (_, block) in swizzle.blocks {
            block(application as AnyObject?, userInfo as AnyObject?, nil)
        }
    }

    @objc func application(_ application: UIApplication, newDidReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // Get the swizzle
        let selector = PushSelectorMapping.deprecatedReceive.original
        guard let originalMethod = class_getInstanceMethod(type(of: self), selector),
            let swizzle = Swizzler.swizzles[originalMethod] else {
                return
        }

        // Perform the original implementation first
        let curriedImplementation = unsafeBitCast(swizzle.originalMethod,
                                                  to: PushSelectorMapping.Signatures.deprecatedReceive)
        curriedImplementation(self, selector, application, userInfo as NSDictionary)

        // Now call our own implementations
        for (_, block) in swizzle.blocks {
            block(application as AnyObject?, userInfo as AnyObject?, nil)
        }
    }

    @objc func applicationSwizzle(_ application: UIApplication, didRegisterPushToken deviceToken: Data) {
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
