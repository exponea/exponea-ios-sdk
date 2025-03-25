//
//  InAppMessagesManagerType.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 29/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

protocol InAppMessagesManagerType {
    var pendingShowRequests: [String: InAppMessagesManager.InAppMessageShowRequest] { get set }
    var sessionStartDate: Date { get set }
    func addToPendingShowRequest(event: [DataType]) async
    func isFetchInAppMessagesDone(for event: [DataType]) async throws -> Bool
    func anonymize()
    func loadMessageToShow(for event: [DataType]) -> InAppMessage?
    func onEventOccurred(of type: EventType, for event: [DataType], triggerCompletion: TypeBlock<IdentifyTriggerState>?)
    func startIdentifyCustomerFlow(
        for event: [DataType],
        isFromIdentifyCustomer: Bool,
        isFetchDisabled: Bool,
        isAnonymized: Bool,
        triggerCompletion: TypeBlock<IdentifyTriggerState>?
    ) async
    func showInAppMessage(
        for type: [DataType],
        callback: ((InAppMessageView?) -> Void)?
    ) async
    func loadMessagesToShow(for event: [DataType]) -> [InAppMessage]
}
