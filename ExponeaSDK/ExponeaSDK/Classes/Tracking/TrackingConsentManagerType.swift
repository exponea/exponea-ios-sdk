//
//  TrackingConsentManagerType.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 23/09/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//

import Foundation

protocol TrackingConsentManagerType {
    func trackInAppMessageClick(message: InAppMessage, buttonText: String?, buttonLink: String?, mode: MODE)
    func trackInAppMessageClose(message: InAppMessage, mode: MODE)
    func trackInAppMessageShown(message: InAppMessage, mode: MODE)
    func trackInAppMessageError(message: InAppMessage, error: String, mode: MODE)
    func trackClickedPush(data: AnyObject?, mode: MODE)
    func trackClickedPush(data: PushOpenedData)
    func trackDeliveredPush(data: NotificationData)
    func trackAppInboxClick(message: MessageItem, buttonText: String?, buttonLink: String?, mode: MODE)
    func trackAppInboxOpened(message: MessageItem, mode: MODE)
}

enum MODE {
    case CONSIDER_CONSENT
    case IGNORE_CONSENT
}
