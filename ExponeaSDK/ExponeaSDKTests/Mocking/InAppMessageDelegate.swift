//
//  InAppMessageDelegate.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 03/02/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//

import Foundation
import ExponeaSDK

class InAppMessageDelegate: InAppMessageActionDelegate {

    let overrideDefaultBehavior: Bool
    let trackActions: Bool
    var inAppMessageActionCalled: Bool = false

    init(
        overrideDefaultBehavior: Bool,
        trackActions: Bool
    ) {
        self.overrideDefaultBehavior = overrideDefaultBehavior
        self.trackActions = trackActions
    }

    func inAppMessageAction(with messageId: String, button: InAppMessageButton?, interaction: Bool) {
        inAppMessageActionCalled = true
    }
}
