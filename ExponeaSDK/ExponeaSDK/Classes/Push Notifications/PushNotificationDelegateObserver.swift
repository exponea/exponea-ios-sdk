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

    @objc var observable: UNUserNotificationCenterDelegating
    var observation: NSKeyValueObservation?

    init(observable: UNUserNotificationCenterDelegating, callback: @escaping Callback) {
        self.observable = observable
        super.init()

        observation = observe(\.observable.delegate, options: [.old, .new]) { _, change in
            guard change.oldValue != nil || change.newValue != nil else {
                return // if they are both nil, do nothing
            }
            guard let old = change.oldValue, let new = change.newValue else {
                callback(change) //one of them is nil, it changed
                return
            }
            if old !== new {
                callback(change) // they are not the same instance, it changed
            }
        }
    }

    deinit {
        if #available(iOS 11.0, *) {} else if let observation = observation {
            removeObserver(observation, forKeyPath: "observable.delegate")
        }
        observation?.invalidate()
    }
}
