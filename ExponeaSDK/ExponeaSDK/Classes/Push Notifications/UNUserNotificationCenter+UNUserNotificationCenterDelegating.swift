//
//  UNUserNotificationCenter+HasUNUserNotificationCenterDelegate.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 07/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation
import UserNotifications

@objc protocol UNUserNotificationCenterDelegating {
    var delegate: UNUserNotificationCenterDelegate? { get set }
}

extension UNUserNotificationCenter: UNUserNotificationCenterDelegating {}

final class BasicUNUserNotificationCenterDelegating: NSObject, UNUserNotificationCenterDelegating {
    // swiftlint:disable:next weak_delegate
    dynamic var delegate: UNUserNotificationCenterDelegate?
}
