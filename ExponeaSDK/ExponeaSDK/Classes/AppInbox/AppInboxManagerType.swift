//
//  AppInboxManagerType.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 27/10/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//

import Foundation

protocol AppInboxManagerType {
    func onEventOccurred(of type: EventType, for event: [DataType])
    func fetchAppInbox(customerIds: [String: String]?, completion: @escaping (Result<[MessageItem]>) -> Void)
    func fetchAppInboxItem(_ messageId: String, completion: @escaping (Result<MessageItem>) -> Void)
    func markMessageAsRead(_ message: MessageItem, _ customerIdsCheck: TypeBlock<Bool>?, _ completition: ((Bool) -> Void)?)
    func clear()
}

extension AppInboxManagerType {
    func fetchAppInbox(customerIds: [String: String]? = nil, completion: @escaping (Result<[MessageItem]>) -> Void) {
        fetchAppInbox(customerIds: customerIds, completion: completion)
    }
}
