//
//  TrackingConsentManagerType.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 23/09/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//

import Foundation

protocol TrackingConsentManagerType {
    func trackInAppMessageClick(message: InAppMessage, buttonText: String?, buttonLink: String?, mode: MODE, isUserInteraction: Bool)
    func trackInAppMessageClose(message: InAppMessage, mode: MODE, isUserInteraction: Bool)
    func trackInAppMessageShown(message: InAppMessage, mode: MODE)
    func trackInAppMessageError(message: InAppMessage, error: String, mode: MODE)
    func trackClickedPush(data: AnyObject?, mode: MODE)
    func trackClickedPush(data: PushOpenedData)
    func trackDeliveredPush(data: NotificationData, mode: MODE)
    func trackAppInboxClick(message: MessageItem, buttonText: String?, buttonLink: String?, mode: MODE)
    func trackAppInboxOpened(message: MessageItem, mode: MODE)
    func trackInlineMessageClick(message: InlineMessageResponse, buttonText: String?, buttonLink: String?, mode: MODE, isUserInteraction: Bool)
    func trackInlineMessageClose(message: InlineMessageResponse, mode: MODE, isUserInteraction: Bool)
    func trackInlineMessageShow(message: InlineMessageResponse, mode: MODE)
}

enum MODE {
    case CONSIDER_CONSENT
    case IGNORE_CONSENT
}
