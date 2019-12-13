//
//  InAppMessagesManagerType.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 29/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

protocol InAppMessagesManagerType {
    func preload(completion: (() -> Void)?)
    func getInAppMessage() -> InAppMessage?
    func showInAppMessage(callback: ((Bool) -> Void)?)
}

extension InAppMessagesManagerType {
    func preload() {
        preload(completion: nil)
    }

    func showInAppMessage() {
        showInAppMessage(callback: nil)
    }
}
