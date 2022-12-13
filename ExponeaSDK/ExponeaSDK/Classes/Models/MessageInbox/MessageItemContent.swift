//
//  MessageItemContent.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 25/10/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//

import Foundation

public struct MessageItemContent: Codable, Equatable {
    public let title: String?
    public let action: String?
    public let actionUrl: String?
    public let message: String?
    public let imageUrl: String?
    public let actions: [MessageItemAction]?
    public let attributes: [String: JSONValue]?
    public let urlParams: [String: String]?
    public let source: String?
    public let silent: Bool
    public let hasTrackingConsent: Bool
    public let consentCategoryTracking: String?

    public var createdAtDate: Date {
        if let attributes = attributes,
           let sentTimestampJson = attributes["sent_timestamp"],
           let sentTimestamp = sentTimestampJson.rawValue as? Double {
            return Date(timeIntervalSince1970: TimeInterval(sentTimestamp))
        }
        return Date()
    }

    var trackingData: [DataType] {
        do {
            let rawContent = try JSONEncoder().encode(self)
            let userInfo = try JSONSerialization.jsonObject(
                with: rawContent, options: []
            ) as AnyObject
            let parsed = PushNotificationParser.parsePushOpened(
                userInfoObject: userInfo,
                actionIdentifier: nil,
                timestamp: self.createdAtDate.timeIntervalSince1970,
                considerConsent: true
            )
            var eventData = parsed?.eventData ?? []
            if let campaingData = parsed?.campaignData.trackingData {
                eventData.append(.properties(campaingData))
            }
            return eventData
        } catch (let error) {
            Exponea.logger.log(.error, message: "Unable to read tracking data: \(error)")
            return []
        }
    }

    enum CodingKeys: String, CodingKey {
        case title
        case action
        case actionUrl = "url"
        case message
        case imageUrl = "image"
        case actions
        case attributes
        case urlParams = "url_params"
        case source
        case silent
        case hasTrackingConsent = "has_tracking_consent"
        case consentCategoryTracking = "consent_category_tracking"
    }
}
