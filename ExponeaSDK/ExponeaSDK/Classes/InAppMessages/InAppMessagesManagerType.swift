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
    func getInAppMessage(for event: [DataType]) -> InAppMessage?
    func showInAppMessage(
        for event: [DataType],
        trackingDelegate: InAppMessageTrackingDelegate?,
        callback: ((InAppMessageView?) -> Void)?
    )
    func sessionDidStart(at date: Date)
    func anonymize()
}

extension InAppMessagesManagerType {
    func preload(for customerIds: [String: JSONValue]) {
        preload(for: customerIds, completion: nil)
    }

    func showInAppMessage(for event: [DataType], trackingDelegate: InAppMessageTrackingDelegate?) {
        showInAppMessage(for: event, trackingDelegate: trackingDelegate, callback: nil)
    }
}
