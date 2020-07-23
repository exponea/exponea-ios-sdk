//
//  InAppMessagesManagerType.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 29/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

protocol InAppMessagesManagerType {
    func preload(for customerIds: [String: String], completion: (() -> Void)?)
    func getInAppMessage(for event: [DataType], requireImage: Bool) -> InAppMessage?
    func showInAppMessage(
        for event: [DataType],
        trackingDelegate: InAppMessageTrackingDelegate?,
        callback: ((InAppMessageView?) -> Void)?
    )
    func sessionDidStart(at date: Date, for customerIds: [String: String], completion: (() -> Void)?)
    func anonymize()
}

extension InAppMessagesManagerType {
    func preload(for customerIds: [String: String]) {
        preload(for: customerIds, completion: nil)
    }

    func showInAppMessage(for event: [DataType], trackingDelegate: InAppMessageTrackingDelegate?) {
        showInAppMessage(for: event, trackingDelegate: trackingDelegate, callback: nil)
    }

    func getInAppMessage(for event: [DataType]) -> InAppMessage? {
        return getInAppMessage(for: event, requireImage: true)
    }
}
