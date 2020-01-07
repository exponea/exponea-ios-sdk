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
    func flushDataWith(delay: Double, completion: (() -> Void)?) {
        completion?()
    }

    func flushData(completion: (() -> Void)?) {
        completion?()
    }

    var flushingMode: FlushingMode = .manual

    func applicationDidBecomeActive() {}

    func applicationDidEnterBackground() {}

}
