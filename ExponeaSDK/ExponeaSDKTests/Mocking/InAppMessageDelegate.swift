//
//  InAppMessageDelegate.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 03/02/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//

import Foundation
@testable import ExponeaSDK

class InAppMessageDelegate: InAppMessageActionDelegate {

    let overrideDefaultBehavior: Bool
    let trackActions: Bool
    var inAppMessageActionCalled: Bool = false
    var trackClickInActionCallback: Bool = false
    var inAppMessageManager: InAppMessagesManager?
    weak var inAppMessageTrackingDelegate: InAppMessageTrackingDelegate?

    init(
        overrideDefaultBehavior: Bool,
        trackActions: Bool,
        trackClickInActionCallback: Bool = false,
        inAppMessageManager: InAppMessagesManager? = nil,
        inAppMessageTrackingDelegate: InAppMessageTrackingDelegate? = nil
    ) {
        self.overrideDefaultBehavior = overrideDefaultBehavior
        self.trackActions = trackActions
        self.trackClickInActionCallback = trackClickInActionCallback
        self.inAppMessageManager = inAppMessageManager
        self.inAppMessageTrackingDelegate = inAppMessageTrackingDelegate
    }

    func inAppMessageAction(with message: InAppMessage, button: InAppMessageButton?, interaction: Bool) {
        inAppMessageActionCalled = true
        if trackClickInActionCallback {
            if let manager = inAppMessageManager, let trackingDelegate = inAppMessageTrackingDelegate {
                manager.trackInAppMessageClick(
                    message,
                    trackingDelegate: trackingDelegate,
                    buttonText: button?.text,
                    buttonLink: button?.url
                )
            }
        }
    }
}
