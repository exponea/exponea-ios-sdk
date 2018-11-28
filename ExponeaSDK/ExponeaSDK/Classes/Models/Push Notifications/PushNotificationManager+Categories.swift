//
//  PushNotificationManager+Categories.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 25/11/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import UserNotifications

extension PushNotificationManager {
    private static func createAppOpenAction(with title: String, index: Int) -> UNNotificationAction {
        return UNNotificationAction(identifier: ExponeaNotificationAction.openApp.rawValue + "_\(index)", title: title,
                                    options: [.foreground])
    }
    
    private static func createBrowserAction(with title: String, index: Int) -> UNNotificationAction {
        return UNNotificationAction(identifier: ExponeaNotificationAction.browser.rawValue + "_\(index)", title: title,
                                    options: [.foreground])
    }
    
    private static func createDeeplinkAction(with title: String, index: Int) -> UNNotificationAction {
        return UNNotificationAction(identifier: ExponeaNotificationAction.deeplink.rawValue + "_\(index)", title: title,
                                    options: [.foreground])
    }
    
    private static let maximumNumberOfNotificationActions = 3
    private static let notificationActionsVariations: [[ExponeaNotificationAction]] = {
        let allActions: [ExponeaNotificationAction] = [.openApp, .browser, .deeplink]
        
        func createVariations(length: Int) -> [[ExponeaNotificationAction]] {
            var indexes: [Int] = Array(repeating: 0, count: length)
            var actions: [[ExponeaNotificationAction]] = [indexes.map({ allActions[$0] })]
            
            while true {
                var index = length - 1
                
                while index >= 0 && indexes[index] == allActions.count - 1 {
                    index -= 1
                }
                
                if index < 0 {
                    break
                }
                
                indexes[index] += 1
                
                for i in index+1..<length {
                    indexes[i] = 0
                }
                
                actions.append(indexes.map({ allActions[$0] }))
            }
            return actions
        }
        
        return createVariations(length: 3) + createVariations(length: 2) + createVariations(length: 1)
    }()
 
    internal static func createNotificationCategories(openAppButtonTitle: String,
                                                      openBrowserButtonTitle: String,
                                                      openDeeplinkButtonTitle: String) -> Set<UNNotificationCategory> {
        func action(for action: ExponeaNotificationAction, index: Int) -> UNNotificationAction {
            switch action {
            case .openApp: return createAppOpenAction(with: openAppButtonTitle, index: index)
            case .browser: return createBrowserAction(with: openBrowserButtonTitle, index: index)
            case .deeplink: return createDeeplinkAction(with: openDeeplinkButtonTitle, index: index)
            default:
                Exponea.logger.log(.error, message: "Error while mapping custom notification actions.")
                return UNNotificationAction(identifier: "EXPONEA_ERROR", title: "",
                                            options: UNNotificationActionOptions(rawValue: 0))
            }
        }
        
        var categories: Set<UNNotificationCategory> = []
        
        // Create all the categories
        for variation in notificationActionsVariations {
            let actions = variation.enumerated().compactMap { (offset, element) -> UNNotificationAction? in
                return action(for: element, index: offset)
            }
            let actionsIds = variation.map({ $0.identifier }).joined(separator: "_")
            let identifier = "EXPONEA_ACTIONABLE_\(variation.count)_\(actionsIds)"
            let category = UNNotificationCategory(identifier: identifier, actions: actions,
                                                  intentIdentifiers: [], options: .customDismissAction)
            categories.insert(category)
        }
        
        return categories
    }
}
