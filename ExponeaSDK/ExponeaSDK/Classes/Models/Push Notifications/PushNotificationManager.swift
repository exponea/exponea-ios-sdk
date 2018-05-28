//
//  PushNotificationManager.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 25/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import UserNotifications

class PushNotificationManager: NSObject {
    /// The tracking manager used to track push events
    internal weak var trackingManager: TrackingManagerType?
    
    /// Used for knowing if we have added push notifications observer
    internal weak var pushObserver: NSKeyValueObservation?
    
    init(trackingManager: TrackingManagerType) {
        self.trackingManager = trackingManager
        
        super.init()
        
        addAutomaticPushTracking()
    }
    
    deinit {
        removeAutomaticPushTracking()
    }
}

extension PushNotificationManager {
    
    private func addAutomaticPushTracking() {
        guard let appDelegate = UIApplication.shared.delegate else {
            return
        }
        
        let appDelegateClass: AnyClass = type(of: appDelegate)
        var swizzleMapping: PushSelectorMapping.Mapping?
        var newClass: AnyClass?
        
        // Monitor push registration
        Swizzler.swizzleSelector(PushSelectorMapping.registration.original,
                                 with: PushSelectorMapping.registration.swizzled,
                                 for: appDelegateClass,
                                 name: "PushTokenRegistration", block: { [weak self] (_, _, _, dataObject) in
            print("swizzle push regi")
            guard let tokenData = dataObject as? Data else {
                return
            }
            let token = tokenData.tokenString
            do {
                try self?.trackingManager?.track(.registerPushToken, with: [DataType.pushNotificationToken(token)])
            } catch {
                Exponea.logger.log(.error, message: "Error logging push token. \(error.localizedDescription)")
            }
        }, addingMethodIfNecessary: true)
        
        // Monitor push delivery
        if let UNDelegate = UNUserNotificationCenter.current().delegate {
            newClass = type(of: UNDelegate)
        } else {
            let center = UNUserNotificationCenter.current()
            pushObserver = center.observe(\.delegate, options: [.old, .new]) { [weak self] (_, _) in
                self?.observePushDelegateChange()
            }
        }
        
        if let newClass = newClass, class_getInstanceMethod(newClass, PushSelectorMapping.newReceive.original) != nil {
            // Check for UNUserNotification's delegate did receive remote notification
            swizzleMapping = PushSelectorMapping.newReceive
        } else if class_getInstanceMethod(appDelegateClass, PushSelectorMapping.handlerReceive.original) != nil {
            // Check for UIAppDelegate's did receive remote notification with fetch completion handler
            swizzleMapping = PushSelectorMapping.handlerReceive
        } else if class_getInstanceMethod(appDelegateClass, PushSelectorMapping.deprecatedReceive.original) != nil {
            // Check for UIAppDelegate's deprecated receive remote notification
            swizzleMapping = PushSelectorMapping.deprecatedReceive
        }
        
        guard let mapping = swizzleMapping else {
            return
        }
        
        let block: Swizzler.SwizzleBlock = { [weak self] (_, _, _, param2: AnyObject?) in
            if let userInfo = param2 as? [AnyHashable: JSONConvertible] {
                // TODO: refactor
                do {
                    try self?.trackingManager?.track(.pushOpened, with: [.properties(userInfo)])
                } catch {
                    Exponea.logger.log(.error, message: "Error tracking push opened. \(error.localizedDescription)")
                }
            }
        }
        
        // Do the swizzling
        Swizzler.swizzleSelector(mapping.original,
                                 with: mapping.swizzled,
                                 for: newClass ?? appDelegateClass,
                                 name: "NotificationOpened",
                                 block: block)
    }
    
    internal func removeAutomaticPushTracking() {
        if let observer = pushObserver {
            observer.invalidate()
            pushObserver = nil
        }
        
        for swizzle in Swizzler.swizzles {
            Swizzler.unswizzle(swizzle.value)
        }
    }
    
    private func observePushDelegateChange() {
        guard let UNDelegate = UNUserNotificationCenter.current().delegate else { return }
        let delegateClass: AnyClass = type(of: UNDelegate)
        let selector = PushSelectorMapping.newReceive.original
        
        guard class_getInstanceMethod(delegateClass, selector) != nil else {
            return
        }
        
        let block: Swizzler.SwizzleBlock = { [weak self] (_, _, _, param2: AnyObject?) in
            if let userInfo = param2 as? [AnyHashable: JSONConvertible] {
                // TODO: refactor
                do {
                    try self?.trackingManager?.track(.pushOpened, with: [.properties(userInfo)])
                } catch {
                    Exponea.logger.log(.error, message: "Error tracking push opened. \(error.localizedDescription)")
                }
            }
        }
        
        // Swizzle the notification delegate notification received function
        Swizzler.swizzleSelector(selector,
                                 with: PushSelectorMapping.newReceive.swizzled,
                                 for: delegateClass,
                                 name: "notification opened", block: block)
    }
}

extension UIResponder {
    @objc func application(_ application: UIApplication,
                           newDidReceiveRemoteNotification userInfo: [AnyHashable: Any],
                           fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let selector = PushSelectorMapping.handlerReceive.original
        guard let originalMethod = class_getInstanceMethod(type(of: self), selector),
            let swizzle = Swizzler.swizzles[originalMethod] else {
                return
        }
        
        typealias MyCFunction = @convention(c) (AnyObject, Selector, UIApplication,
            NSDictionary, (UIBackgroundFetchResult) -> Void) -> Void
        
        let curriedImplementation = unsafeBitCast(swizzle.originalMethod, to: MyCFunction.self)
        curriedImplementation(self, selector, application, userInfo as NSDictionary, completionHandler)
        
        for (_, block) in swizzle.blocks {
            block(self, swizzle.selector, application as AnyObject?, userInfo as AnyObject?)
        }
    }
    
    @objc func application(_ application: UIApplication, newDidReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        let selector = PushSelectorMapping.deprecatedReceive.original
        if let originalMethod = class_getInstanceMethod(type(of: self), selector),
            let swizzle = Swizzler.swizzles[originalMethod] {
            
            typealias MyCFunction = @convention(c) (AnyObject, Selector, UIApplication, NSDictionary) -> Void
            
            let curriedImplementation = unsafeBitCast(swizzle.originalMethod, to: MyCFunction.self)
            curriedImplementation(self, selector, application, userInfo as NSDictionary)
            
            for (_, block) in swizzle.blocks {
                block(self, swizzle.selector, application as AnyObject?, userInfo as AnyObject?)
            }
        }
    }
    
    @objc func applicationSwizzle(
        _ application: UIApplication,
        didRegisterPushToken deviceToken: Data) {
        let selector = PushSelectorMapping.registration.original
        if let originalMethod = class_getInstanceMethod(type(of: self), selector),
            let swizzle = Swizzler.swizzles[originalMethod] {
            typealias MyCFunction = @convention(c) (AnyObject, Selector, UIApplication, Data) -> Void
            let curriedImplementation = unsafeBitCast(swizzle.originalMethod, to: MyCFunction.self)
            curriedImplementation(self, selector, application, deviceToken)
            
            for (_, block) in swizzle.blocks {
                block(self, swizzle.selector, application as AnyObject?, deviceToken as AnyObject?)
            }
        }
    }
}

extension NSObject {
    @objc func userNotificationCenter(_ center: UNUserNotificationCenter,
                                      newDidReceive response: UNNotificationResponse,
                                      withCompletionHandler completionHandler: @escaping () -> Void) {
        let selector = PushSelectorMapping.newReceive.original
        
        guard let originalMethod = class_getInstanceMethod(type(of: self), selector),
            let swizzle = Swizzler.swizzles[originalMethod] else {
                return
        }
        
        typealias MyCFunction = @convention(c) (
            AnyObject, Selector, UNUserNotificationCenter, UNNotificationResponse,
            () -> Void) -> Void
        
        let curriedImplementation = unsafeBitCast(swizzle.originalMethod, to: MyCFunction.self)
        curriedImplementation(self, selector, center, response, completionHandler)
        
        for (_, block) in swizzle.blocks {
            block(self,
                  swizzle.selector,
                  center as AnyObject?,
                  response.notification.request.content.userInfo as AnyObject?)
        }
    }
}
