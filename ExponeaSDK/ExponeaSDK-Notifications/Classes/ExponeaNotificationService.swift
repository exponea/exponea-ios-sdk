//
//  ExponeaNotificationService.swift
//  ExponeaSDKNotifications
//
//  Created by Dominik Hadl on 22/11/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import UserNotifications

public class ExponeaNotificationService {

    private let appGroup: String?

    var request: UNNotificationRequest?
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    public init(appGroup: String? = nil) {
        self.appGroup = appGroup
    }

    public func process(request: UNNotificationRequest, contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.request = request
        self.contentHandler = contentHandler

        createContent()
    }

    public func serviceExtensionTimeWillExpire() {
        // Clean, after we are finished
        defer { clean() }

        // Try to call content handler with current content
        if let content = bestAttemptContent {
            contentHandler?(content)
        }
    }

    internal func createContent() {
        // Create a mutable content and make sure it works
        bestAttemptContent = (request?.content.mutableCopy() as? UNMutableNotificationContent)

        // Modify
        if let content = bestAttemptContent {
            bestAttemptContent?.title = content.userInfo["title"] as? String ?? "NO TITLE"
            bestAttemptContent?.body = content.userInfo["message"] as? String ?? ""

            if #available(iOSApplicationExtension 12.0, *) {
                bestAttemptContent?.categoryIdentifier = "EXPONEA_ACTIONABLE"
            }

            // Assign badge if any
            if let badgeString = content.userInfo["badge"] as? String, let badge = Int(badgeString) {
                bestAttemptContent?.badge = badge as NSNumber
            } else {
                bestAttemptContent?.badge = nil
            }

            // Assign sound if any
            if let sound = content.userInfo["sound"] as? String {
                bestAttemptContent?.sound = UNNotificationSound.init(named: UNNotificationSoundName(rawValue: sound))
            }

            // Download and add image
            if let imagePath = content.userInfo["image"] as? String,
                let url = URL(string: imagePath),
                let data = try? Data(contentsOf: url, options: []),
                let attachment = save("image.png", data: data, options: nil) {
                bestAttemptContent?.attachments = [attachment]
            }

            saveNotificationForLaterTracking(userInfo: content.userInfo)
        }

        // We're done modifying, notify
        if let content = bestAttemptContent {
            contentHandler?(content)
        }

        // Finally clean
        clean()
    }

    func saveNotificationForLaterTracking(userInfo: [AnyHashable: Any]) {
        guard let appGroup = appGroup else {
            return
        }
        guard let userDefaults = UserDefaults(suiteName: appGroup) else {
            return
        }

        let attributes = userInfo["attributes"] as? [String: Any] ?? [:]
        let notification = NotificationData.deserialize(from: attributes) ?? NotificationData()

        if let serialized = notification.serialize() {
            var delivered = userDefaults.array(forKey: Constants.General.deliveredPushUserDefaultsKey) ?? []
            delivered.append(serialized)
            userDefaults.set(delivered, forKey: Constants.General.deliveredPushUserDefaultsKey)
        }
    }

    func save(_ identifier: String, data: Data, options: [AnyHashable: Any]?) -> UNNotificationAttachment? {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
        let directory = url.appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString, isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: directory,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
            let fileURL = directory.appendingPathComponent(identifier)
            try data.write(to: fileURL, options: [])
            return try UNNotificationAttachment.init(identifier: identifier,
                                                     url: fileURL,
                                                     options: options)

        } catch {
            return nil
        }
    }

    internal func clean() {
        self.request = nil
        self.contentHandler = nil
        self.bestAttemptContent = nil
    }
}
