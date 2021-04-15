//
//  PushNotificationParser.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 23/10/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation
import UserNotifications

struct PushNotificationParser {
    static let decoder: JSONDecoder = JSONDecoder.snakeCase

    static func parsePushOpened(userInfoObject: AnyObject?,
                                actionIdentifier: String?,
                                timestamp: Double) -> PushOpenedData? {
        guard let userInfo = userInfoObject as? [String: Any] else {
            Exponea.logger.log(.error, message: "Failed to convert push payload.")
            return nil
        }

        let silent = userInfo["silent"] as? Int == 1
        var eventData: [DataType] = []
        var eventType = silent ? EventType.pushDelivered : EventType.pushOpened
        var properties: [String: JSONValue] = [
            "status": .string(silent ? "delivered" : "clicked"),
            "cta": .string("notification"),
            "url": .string("app")
        ]
        let notificationData = NotificationData.deserialize(
            attributes: userInfo["attributes"] as? [String: Any] ?? [:],
            campaignData: userInfo["url_params"] as? [String: Any] ?? [:]
        ) ?? NotificationData()
        properties.merge(notificationData.properties) { (current, _) in current }
        if let customEventType = notificationData.eventType,
           !customEventType.isEmpty,
           customEventType != Constants.EventTypes.pushOpen {
            eventType = .customEvent
            eventData.append(.eventType(customEventType))
        }

        // Handle actions

        let action: ExponeaNotificationActionType
        let actionValue: String?

        // If we have action identifier then a button was pressed
        if let identifier = actionIdentifier, identifier != UNNotificationDefaultActionIdentifier {
            // Fetch action (only a value if a custom button was pressed)
            // Format of action id should look like - EXPONEA_APP_OPEN_ACTION_0
            // We need to get the right index and fetch the correct action url from payload, if any
            let indexString = identifier.components(separatedBy: "_").last
            if let indexString = indexString, let index = Int(indexString),
                let actions = userInfo["actions"] as? [[String: String]], actions.count > index {
                let actionDict = actions[index]
                action = ExponeaNotificationActionType(rawValue: actionDict["action"] ?? "") ?? .none
                actionValue = actionDict["url"]

                // Track the notification action title
                if let name = actionDict["title"] {
                    properties["cta"] = .string(name)
                }

            } else {
                action = .none
                actionValue = nil
            }
        } else {
            // Fetch notification action (on tap of notification)
            let notificationActionString = (userInfo["action"] as? String ?? "")
            action = ExponeaNotificationActionType(rawValue: notificationActionString) ?? .none
            actionValue = userInfo["url"] as? String
        }

        switch action {
        case .none, .openApp, .selfCheck:
            break

        case .browser, .deeplink:
            if let value = actionValue, URL(string: value) != nil {
                properties["url"] = .string(value)
            }
        }

        eventData.append(.properties(properties))
        let currentTimestamp = timestamp
        let deliveredTimestamp = userInfo["delivered_timestamp"] as? Double ?? 0
        let openedTimestamp = currentTimestamp <= deliveredTimestamp ? deliveredTimestamp + 1 : currentTimestamp
        eventData.append(.timestamp(openedTimestamp))

        return PushOpenedData(
            silent: silent,
            campaignData: notificationData.campaignData,
            actionType: action,
            actionValue: actionValue,
            eventType: eventType,
            eventData: eventData,
            extraData: userInfo["attributes"] as? [String: Any]
        )
    }
}
