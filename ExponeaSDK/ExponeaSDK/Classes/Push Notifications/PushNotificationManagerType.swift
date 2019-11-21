//
//  PushNotificationManagerType.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 07/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

protocol PushNotificationManagerType: class {
    var delegate: PushNotificationManagerDelegate? { get set }
    func applicationDidBecomeActive()
    func handlePushOpened(userInfoObject: AnyObject?, actionIdentifier: String?)
    func handlePushTokenRegistered(dataObject: AnyObject?)
}
