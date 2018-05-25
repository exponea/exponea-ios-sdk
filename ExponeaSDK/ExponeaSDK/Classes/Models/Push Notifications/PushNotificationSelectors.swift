//
//  PushNotificationSelectors.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 25/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

internal enum PushSelectorMapping {
    internal typealias Mapping = (original: Selector, swizzled: Selector)
    
    internal enum Original {
        static let registration = #selector(
            UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:)
        )
        
        static let newReceive = NSSelectorFromString(
            "userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:"
        )
        
        static let handlerReceive = NSSelectorFromString(
            "application:didReceiveRemoteNotification:fetchCompletionHandler:"
        )
        
        static let deprecatedReceive = NSSelectorFromString(
            "application:didReceiveRemoteNotification:"
        )
    }
    
    internal enum Swizzled {
        static let registration = #selector(
            UIResponder.applicationSwizzle(_:didRegisterPushToken:)
        )
        
        static let newReceive = #selector(
            NSObject.userNotificationCenter(_:newDidReceive:withCompletionHandler:)
        )
        
        static let handlerReceive = #selector(
            UIResponder.application(_:newDidReceiveRemoteNotification:fetchCompletionHandler:)
        )
        
        static let deprecatedReceive = #selector(
            UIResponder.application(_:newDidReceiveRemoteNotification:)
        )
    }
    
    internal static let registration: Mapping = (Original.registration, Swizzled.registration)
    internal static let newReceive: Mapping = (Original.newReceive, Swizzled.newReceive)
    internal static let handlerReceive: Mapping = (Original.handlerReceive, Swizzled.handlerReceive)
    internal static let deprecatedReceive: Mapping = (Original.deprecatedReceive, Swizzled.deprecatedReceive)
}
