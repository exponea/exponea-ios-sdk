//
//  MockInAppMessagesManager.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 03/09/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

@testable import ExponeaSDK

final class MockInAppMessagesManager: InAppMessagesManagerType {
    func isFetchInAppMessagesDone(for event: [ExponeaSDK.DataType]) async throws -> Bool {
        true
    }
    
    func startIdentifyCustomerFlow(for event: [ExponeaSDK.DataType], isFromIdentifyCustomer: Bool, isFetchDisabled: Bool, isAnonymized: Bool, triggerCompletion: ExponeaSDK.TypeBlock<ExponeaSDK.IdentifyTriggerState>?) {
        
    }
    
    func startIdentifyCustomerFlow(for event: [ExponeaSDK.DataType], isFromIdentifyCustomer: Bool, isFetchDisabled: Bool, triggerCompletion: ExponeaSDK.TypeBlock<ExponeaSDK.IdentifyTriggerState>?) {}
    func addToPendingShowRequest(event: [ExponeaSDK.DataType]) {}
    func loadMessagesToShow(for event: [ExponeaSDK.DataType]) -> [ExponeaSDK.InAppMessage] { [] }
    func showInAppMessage(for type: [ExponeaSDK.DataType], callback: ((ExponeaSDK.InAppMessageView?) -> Void)?) {}
    func fetchInAppMessages(for event: [ExponeaSDK.DataType], completion: ExponeaSDK.EmptyBlock?) {}
    func loadMessageToShow(
        for event: [ExponeaSDK.DataType]
    ) -> ExponeaSDK.InAppMessage? { nil }
    var sessionStartDate: Date = .init()
    func onEventOccurred(
        of type: ExponeaSDK.EventType,
        for event: [ExponeaSDK.DataType],
        triggerCompletion: ExponeaSDK.TypeBlock<ExponeaSDK.IdentifyTriggerState>?
    ) {}
    var pendingShowRequests: [String: ExponeaSDK.InAppMessagesManager.InAppMessageShowRequest] = [:]
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
