//
//  ExponeaSDKQuickConfiguration.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 11/03/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Quick
@testable import ExponeaSDK

class ExponeaSDKQuickConfiguration: QuickConfiguration {
    override class func configure(_ configuration: Quick.Configuration) {
        _ = MockUserNotificationCenter.shared
        UNAuthorizationStatusProvider.current = MockUNAuthorizationStatusProviding(status: .authorized)
    }
}
