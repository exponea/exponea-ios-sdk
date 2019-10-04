//
//  MockUserNotificationCenter.swift
//  ExponeaSDKTests
//
//  Created by Dominik Hadl on 25/10/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import UserNotifications

@testable import ExponeaSDK

@objc(MockUserNotificationCenter)
class MockUserNotificationCenter: NSObject {

    static let shared = MockUserNotificationCenter()

    private let swizzling = Swizzling()

    // Swizzle
    private struct Swizzling {
        static let originalSelector = NSSelectorFromString("currentNotificationCenter")
        static let newSelector = #selector(MockUserNotificationCenter.overrideCurrentCenter)
        let origMethod: Method = class_getClassMethod(UNUserNotificationCenter.self, originalSelector)!
        let newMethod: Method = class_getInstanceMethod(MockUserNotificationCenter.self, newSelector)!
    }

    override init() {
        super.init()
        // swizzle
        method_exchangeImplementations(swizzling.origMethod, swizzling.newMethod)
    }

    deinit {
        // Change back
        method_exchangeImplementations(swizzling.origMethod, swizzling.newMethod)
    }

    // MARK: - Swizzles -

    @objc func overrideCurrentCenter() -> Self {
        return self
    }
}
