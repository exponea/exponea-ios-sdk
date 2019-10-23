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
    struct PushOpenedData {
        let actionType: ExponeaNotificationActionType
        let actionValue: String?
        let eventData: [DataType]
        let extraData: [String: Any]?
    }

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    static func parsePushOpened(userInfoObject: AnyObject?, actionIdentifier: String?) -> PushOpenedData? {
        guard let userInfo = userInfoObject as? [String: Any] else {
            Exponea.logger.log(.error, message: "Failed to convert push payload.")
            return nil
        }

        var properties: [String: JSONValue] = [:]
        let attributes = userInfo["attributes"] as? [String: Any]

        // If attributes is present, then campaign tracking info is nested in there, decode and process it
        if let attributes = attributes,
            let data = try? JSONSerialization.data(withJSONObject: attributes, options: []),
            let model = try? decoder.decode(NotificationData.self, from: data) {
            properties = model.properties
        } else if let notificationData = userInfo["data"] as? [String: Any],
            let data = try? JSONSerialization.data(withJSONObject: notificationData, options: []),
            let model = try? decoder.decode(NotificationData.self, from: data) {
            properties = model.properties
        }

        properties["status"] = .string("clicked")
        properties["os_name"] = .string("iOS")
        properties["platform"] = .string("iOS")
        properties["action_type"] = .string("mobile notification")

        // Handle actions

        let action: ExponeaNotificationActionType
        let actionValue: String?

        // If we have action identifier then a button was pressed
        if let identifier = actionIdentifier, identifier != UNNotificationDefaultActionIdentifier {
            // Track this notification action type as button press
            properties["notification_action_type"] = .string("button")

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
                    properties["notification_action_name"] = .string(name)
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

            // This was a press directly on notification insted of a button so track it as action type
            properties["notification_action_type"] = .string("notification")
        }

        switch action {
        case .none, .openApp:
            break

        case .browser, .deeplink:
            if let value = actionValue, URL(string: value) != nil {
                properties["notification_action_url"] = .string(value)
            }
        }

        return PushOpenedData(
            actionType: action,
            actionValue: actionValue,
            eventData: [.properties(properties)],
            extraData: attributes
        )
    }
}
