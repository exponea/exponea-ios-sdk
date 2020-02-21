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
        let message: InAppMessage
        let action: String
        let interaction: Bool
    }
    public var calls: [CallData] = []

    func track(message: InAppMessage, action: String, interaction: Bool) {
        calls.append(CallData(message: message, action: action, interaction: interaction))
    }
}
