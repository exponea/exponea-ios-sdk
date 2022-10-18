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
        callback: ((InAppMessageView?) -> Void)?
    ) {}

    func getInAppMessage(for event: [DataType], requireImage: Bool) -> InAppMessage? { return nil }

    func preload(for customerIds: [String: String], completion: (() -> Void)?) {}

    func sessionDidStart(at date: Date, for customerIds: [String: String], completion: (() -> Void)?) {}

    func anonymize() {}

    private var delegateValue: InAppMessageActionDelegate = DefaultInAppDelegate()
    internal var delegate: InAppMessageActionDelegate {
        get {
            return delegateValue
        }
        set {
            delegateValue = newValue
        }
    }
    func trackInAppMessageClick(
        _ message: InAppMessage,
        buttonText: String?,
        buttonLink: String?
    ) {}

    func trackInAppMessageClose(
        _ message: InAppMessage
    ) {}

    func onEventOccurred(of type: EventType, for event: [ExponeaSDK.DataType]) {}
}
