//
//  MockInAppMessagesManager.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 03/09/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

@testable import ExponeaSDK

final class MockInAppMessagesManager: InAppMessagesManagerType {
    func showInAppMessage(
        for event: [DataType],
        trackingDelegate: InAppMessageTrackingDelegate?,
        callback: ((InAppMessageView?) -> Void)?
    ) {}

    func getInAppMessage(for event: [DataType], requireImage: Bool) -> InAppMessage? { return nil }

    func preload(for customerIds: [String: String], completion: (() -> Void)?) {}

    func sessionDidStart(at date: Date, for customerIds: [String: String], completion: (() -> Void)?) {}

    func anonymize() {}
}
