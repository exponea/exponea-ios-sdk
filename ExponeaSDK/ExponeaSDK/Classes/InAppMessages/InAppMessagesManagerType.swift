//
//  InAppMessagesManagerType.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 29/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

protocol InAppMessagesManagerType {
    func preload(for customerIds: [String: JSONValue], completion: (() -> Void)?)
    func getInAppMessage(for eventType: String) -> InAppMessage?
    func showInAppMessage(for eventType: String, callback: ((Bool) -> Void)?)
}

extension InAppMessagesManagerType {
    func preload(for customerIds: [String: JSONValue]) {
        preload(for: customerIds, completion: nil)
    }

    func showInAppMessage(for eventType: String) {
        showInAppMessage(for: eventType, callback: nil)
    }
}
