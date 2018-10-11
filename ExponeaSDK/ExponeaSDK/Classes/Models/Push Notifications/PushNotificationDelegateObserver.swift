//
//  PushNotificationDelegateObserver.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 11/10/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import UserNotifications

class PushNotificationDelegateObserver: NSObject {
    typealias Callback = (NSKeyValueObservedChange<UNUserNotificationCenterDelegate?>) -> Void
    
    @objc var center: UNUserNotificationCenter
    var observation: NSKeyValueObservation?
    
    let callback: Callback
    
    init(center: UNUserNotificationCenter,
         callback: @escaping Callback) {
        self.center = center
        self.callback = callback
        super.init()
        
        observation = observe(\.center.delegate, options: [.old, .new]) { object, change in
            callback(change)
        }
    }
    
    deinit {
        observation?.invalidate()
    }
}
