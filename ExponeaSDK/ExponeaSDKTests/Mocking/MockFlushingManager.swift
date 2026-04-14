//
//  MockFlushingManager.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 13/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation
@testable import ExponeaSDK

internal class MockFlushingManager: FlushingManagerType {
    var inAppRefreshCallback: ExponeaSDK.EmptyBlock?
    
    func flushDataWith(delay: Double, completion: ((FlushResult) -> Void)?) {
        completion?(.noInternetConnection)
    }

    func flushData(isFromIdentify: Bool, completion: ((FlushResult) -> Void)?) {
        completion?(.noInternetConnection)
    }

    var flushingMode: FlushingMode = .manual

    func applicationDidBecomeActive() {}

    func applicationDidEnterBackground() {}

    func hasPendingData() -> Bool { return false }
}
