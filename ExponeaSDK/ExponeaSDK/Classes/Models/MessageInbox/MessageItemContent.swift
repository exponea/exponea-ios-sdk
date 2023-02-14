//
//  MessageItemContent.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 25/10/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//

import Foundation

public struct MessageItemContent {
    public let imageUrl: String?
    public let title: String?
    public let message: String?
    public let consentCategoryTracking: String?
    public let hasTrackingConsent: Bool
    public let trackingData: [String: JSONValue]?
    public let actions: [MessageItemAction]?
    public let action: MessageItemAction?
    public let html: String?
}
