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
    func trackInAppMessageClose(message: InAppMessage, buttonText: String?, mode: MODE, isUserInteraction: Bool)
    func trackInAppMessageShown(message: InAppMessage, mode: MODE)
    func trackInAppMessageError(message: InAppMessage, error: String, mode: MODE)
    func trackClickedPush(data: AnyObject?, mode: MODE)
    func trackClickedPush(data: PushOpenedData)
    func trackDeliveredPush(data: NotificationData, mode: MODE)
    func trackAppInboxClick(message: MessageItem, buttonText: String?, buttonLink: String?, mode: MODE)
    func trackAppInboxOpened(message: MessageItem, mode: MODE)
    func trackInAppContentBlockClick(
        placeholderId: String,
        message: InAppContentBlockResponse,
        action: InAppContentBlockAction,
        mode: MODE
    )
    func trackInAppContentBlockClose(placeholderId: String, message: InAppContentBlockResponse, mode: MODE)
    func trackInAppContentBlockShow(placeholderId: String, message: InAppContentBlockResponse, mode: MODE)
    func trackInAppContentBlockError(
        placeholderId: String,
        message: InAppContentBlockResponse,
        errorMessage: String,
        mode: MODE
    )
}

enum MODE {
    case CONSIDER_CONSENT
    case IGNORE_CONSENT
}
