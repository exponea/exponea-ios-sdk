//
//  PushNotificationCategories.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 22/11/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import UserNotifications

extension Exponea {
    private func createAppOpenAction(with title: String) -> UNNotificationAction {
        return UNNotificationAction(identifier: "EXPONEA_APP_OPEN_ACTION", title: title,
                                    options: UNNotificationActionOptions(rawValue: 0))
    }
    
    private func createBrowserAction(with title: String) -> UNNotificationAction {
        return UNNotificationAction(identifier: "EXPONEA_BROWSER_ACTION", title: title,
                                    options: UNNotificationActionOptions(rawValue: 0))
    }
    
    private func createDeeplinkAction(with title: String) -> UNNotificationAction {
        return UNNotificationAction(identifier: "EXPONEA_DEEPLINK_ACTION", title: title,
                                    options: UNNotificationActionOptions(rawValue: 0))
    }
    
    // We need to create categories for all combinations
    public func createNotificationCategories(openAppButtonTitle: String,
                                             openBrowserButtonTitle: String,
                                             openDeeplinkButtonTitle: String) -> Set<UNNotificationCategory> {
        let combinations = [["APP"], ["BROWSER"], ["DEEPLINK"], // 1 button
                            ["APP", "APP"], ["APP", "BROWSER"], ["APP", "DEEPLINK"], // 2 button, open app first
                            ["BROWSER", "BROWSER"], ["BROWSER", "APP"], ["BROWSER", "DEEPLINK"], // 2 button, browser
                            ["DEEPLINK", "DEEPLINK"], ["DEEPLINK", "APP"], ["DEEPLINK", "BROWSER"]] // 2 button, deep
        
        func action(for key: String) -> UNNotificationAction {
            switch key {
            case "APP": return createAppOpenAction(with: openAppButtonTitle)
            case "BROWSER": return createBrowserAction(with: openBrowserButtonTitle)
            case "DEEPLINK": return createDeeplinkAction(with: openDeeplinkButtonTitle)
            default:
                Exponea.logger.log(.error, message: "Error while mapping custom notification actions.")
                return UNNotificationAction(identifier: "EXPONEA_ERROR", title: "",
                                            options: UNNotificationActionOptions(rawValue: 0))
            }
        }
        
        var categories: Set<UNNotificationCategory> = []
        
        // Create all the categories
        for combination in combinations {
            let actions = combination.map(action(for:))
            let identifier = "EXPONEA_ACTIONABLE_\(combination.count)_\(combination.joined(separator: "_"))"
            let category = UNNotificationCategory(identifier: identifier,
                                                  actions: actions,
                                                  intentIdentifiers: [],
                                                  options: .customDismissAction)
            categories.insert(category)
        }
        
        return categories
    }
}
