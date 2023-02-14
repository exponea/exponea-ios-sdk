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
    func fetchAppInbox(completion: @escaping (Result<[MessageItem]>) -> Void)
    func fetchAppInboxItem(_ messageId: String, completion: @escaping (Result<MessageItem>) -> Void)
    func markMessageAsRead(_ message: MessageItem, _ completition: ((Bool) -> Void)?)
    func clear()
}
