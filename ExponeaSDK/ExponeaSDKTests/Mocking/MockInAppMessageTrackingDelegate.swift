//
//  MockInAppMessageTrackingDelegate.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 16/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

@testable import ExponeaSDK

class MockInAppMessageTrackingDelegate: InAppMessageTrackingDelegate {
    struct CallData: Equatable {
        let event: InAppMessageEvent
        let message: InAppMessage
    }
    public var calls: [CallData] = []

    public func track(_ event: InAppMessageEvent, for message: InAppMessage) {
        calls.append(CallData(event: event, message: message))
    }
}
