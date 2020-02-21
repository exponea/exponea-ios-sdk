//
//  MockPushNotificationManager.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 07/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

@testable import ExponeaSDK

final class MockPushNotificationManager: PushNotificationManagerType {
    weak var delegate: PushNotificationManagerDelegate?

    var handlePushOpenedCalls: [(userInfoObject: AnyObject?, actionIdentifier: String?)] = []
    var handlePushTokenRegisteredCalls: [AnyObject?] = []

    func applicationDidBecomeActive() {
        fatalError("not implemented")
    }

    func handlePushOpened(userInfoObject: AnyObject?, actionIdentifier: String?) {
        handlePushOpenedCalls.append((userInfoObject, actionIdentifier))
    }

    func handlePushTokenRegistered(dataObject: AnyObject?) {
        handlePushTokenRegisteredCalls.append(dataObject)
    }

}
