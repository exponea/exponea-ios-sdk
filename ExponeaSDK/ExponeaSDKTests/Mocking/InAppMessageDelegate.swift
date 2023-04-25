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
    var trackingConsentManager: TrackingConsentManagerType?

    init(
        overrideDefaultBehavior: Bool,
        trackActions: Bool,
        trackClickInActionCallback: Bool = false,
        inAppMessageManager: InAppMessagesManager? = nil,
        trackingConsentManager: TrackingConsentManagerType? = nil
    ) {
        self.overrideDefaultBehavior = overrideDefaultBehavior
        self.trackActions = trackActions
        self.trackClickInActionCallback = trackClickInActionCallback
        self.inAppMessageManager = inAppMessageManager
        self.trackingConsentManager = trackingConsentManager
    }

    func inAppMessageAction(with message: InAppMessage, button: InAppMessageButton?, interaction: Bool) {
        inAppMessageActionCalled = true
        if trackClickInActionCallback {
            if let trackingConsentManager = trackingConsentManager {
                trackingConsentManager.trackInAppMessageClick(
                    message: message,
                    buttonText: button?.text,
                    buttonLink: button?.url,
                    mode: .CONSIDER_CONSENT,
                    isUserInteraction: true
                )
            }
        }
    }
}
