//
//  AppInboxParser.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 21/12/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//

import Foundation

final class AppInboxParser {

    static func parseFromPushNotification(_ source: [String: JSONValue]?) -> MessageItemContent? {
        do {
            let userInfo = try normalizeData(source)
            let parsed = PushNotificationParser.parsePushOpened(
                userInfoObject: userInfo as AnyObject,
                actionIdentifier: nil,
                timestamp: 0,
                considerConsent: true
            )
            var trackingData: [String: JSONValue] = [:]
            if let trackingProperties = parsed?.eventData.properties {
                trackingProperties.forEach { (key: String, value: JSONConvertible?) in
                    if let value = value {
                        trackingData.updateValue(value.jsonValue, forKey: key)
                    }
                }
            }
            if let campaingData = parsed?.campaignData.trackingData {
                trackingData.merge(campaingData, uniquingKeysWith: { _, new in new })
            }
            let actionsSource = userInfo["actions"] as? [[String: String]]
            let actions: [MessageItemAction]? = actionsSource?.map { actionDict in
                MessageItemAction(
                    action: actionDict["action"],
                    title: actionDict["title"],
                    url: actionDict["url"]
                )
            }
            var mainAction: MessageItemAction?
            if let mainActionType = userInfo["action"] as? String {
                mainAction = MessageItemAction(
                    action: mainActionType,
                    title: nil,
                    url: userInfo["url"] as? String
                )
            }
            return MessageItemContent(
                imageUrl: userInfo["image"] as? String,
                title: userInfo["title"] as? String,
                message: userInfo["message"] as? String,
                consentCategoryTracking: userInfo["consent_category_tracking"] as? String,
                hasTrackingConsent: GdprTracking.readTrackingConsentFlag(userInfo["has_tracking_consent"]),
                trackingData: trackingData,
                actions: actions,
                action: mainAction,
                html: nil
            )
        } catch let error {
            Exponea.logger.log(.error, message: "Unable to read AppInbox message content data: \(error)")
            return nil
        }
    }

    static func parseFromHtmlMessage(_ source: [String: JSONValue]?) -> MessageItemContent? {
        do {
            let normalized = try normalizeData(source)
            let htmlOrigin = normalized["message"] as? String
            var actions: [MessageItemAction] = []
            if let htmlOrigin = htmlOrigin {
                let htmlContent = HtmlNormalizer(htmlOrigin).normalize(HtmlNormalizerConfig(
                    makeResourcesOffline: false,
                    ensureCloseButton: false
                ))
                htmlContent.actions.forEach { htmlAction in
                    let actionType: MessageItemActionType
                    switch htmlAction.actionType {
                    case .browser:
                        actionType = .browser
                    case .deeplink:
                        actionType = .deeplink
                    case .close:
                        actionType = .noAction
                    }
                    if actionType != .noAction {
                        actions.append(MessageItemAction(
                            action: actionType.rawValue,
                            title: htmlAction.buttonText,
                            url: htmlAction.actionUrl
                        ))
                    }
                }
            }
            var trackingData: [String: JSONValue] = [:]
            let attributes = (normalized["attributes"] as? [String: Any?] ?? [:])
                .filter { $0.value != nil }
                .filter { $0.key != "event_type" }
                .mapValues { $0! }
            let campaignData = CampaignData(source: normalized["url_params"] as? [String: Any?] ?? [:])
            trackingData.merge(JSONValue.convert(attributes)) { _, new in new }
            trackingData.merge(campaignData.trackingData) { _, new in new }
            return MessageItemContent(
                imageUrl: normalized["image"] as? String,
                title: normalized["title"] as? String,
                message: normalized["pre_header"] as? String,
                consentCategoryTracking: normalized["consent_category_tracking"] as? String,
                hasTrackingConsent: GdprTracking.readTrackingConsentFlag(normalized["has_tracking_consent"]),
                trackingData: trackingData,
                actions: actions,
                action: nil,
                html: htmlOrigin
            )
        } catch let error {
            Exponea.logger.log(.error, message: "Unable to read AppInbox message content data: \(error)")
            return nil
        }
    }

    private static func normalizeData(_ source: [String: JSONValue]?) throws -> [String: Any?] {
        let rawContent = try JSONEncoder().encode(source)
        let normalized = try JSONSerialization.jsonObject(
            with: rawContent, options: []
        ) as? [String: Any?]
        return normalized ?? [:]
    }
}
