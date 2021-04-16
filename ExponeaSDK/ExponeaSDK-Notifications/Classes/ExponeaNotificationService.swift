//
//  ExponeaNotificationService.swift
//  ExponeaSDKNotifications
//
//  Created by Dominik Hadl on 22/11/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import UserNotifications
#if !COCOAPODS
import ExponeaSDKShared
#endif

public class ExponeaNotificationService {

    private let appGroup: String?

    var request: UNNotificationRequest?
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    var notificationTracked: Bool = false {
        didSet {
            checkDone()
        }
    }
    var contentCreated: Bool = false {
        didSet {
            checkDone()
        }
    }

    public init(appGroup: String? = nil) {
        self.appGroup = appGroup
    }

    public func process(request: UNNotificationRequest, contentHandler: @escaping (UNNotificationContent) -> Void) {
        guard Exponea.isExponeaNotification(userInfo: request.content.userInfo) else {
            Exponea.logger.log(.verbose, message: "Skipping non-Exponea notification")
            return
        }
        self.request = request
        self.contentHandler = contentHandler

        if let notificationData = prepareNotificationData(request: request),
           let appGroup = appGroup {
            trackDeliveredNotification(appGroup: appGroup, notificationData: notificationData)
            createContent(deliveredTimestamp: notificationData.timestamp)
        }
    }

    public func serviceExtensionTimeWillExpire() {
        // Clean, after we are finished
        defer { clean() }

        // we failed to track notification
        if !notificationTracked {
            if let userInfo = (request?.content.mutableCopy() as? UNMutableNotificationContent)?.userInfo {
            let notification = NotificationData.deserialize(
                attributes: userInfo["attributes"] as? [String: Any] ?? [:],
                campaignData: userInfo["url_params"] as? [String: Any] ?? [:]
            ) ?? NotificationData()
            saveNotificationForLaterTracking(notification: notification)
            }
        }

        // Try to call content handler with current content
        if let content = bestAttemptContent {
            contentHandler?(content)
        }
    }

    internal func createContent(deliveredTimestamp: Double?) {
        // Create a mutable content and make sure it works
        bestAttemptContent = (request?.content.mutableCopy() as? UNMutableNotificationContent)

        if deliveredTimestamp != nil {
            var additionalInfo = [String: Any]()
            additionalInfo["delivered_timestamp"] = deliveredTimestamp
            bestAttemptContent?.userInfo.merge(additionalInfo) { (_, new) in new }
        }

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
                let attachment = saveImage("image.png", data: data, options: nil) {
                bestAttemptContent?.attachments = [attachment]
            }
        }
        contentCreated = true
    }

    func trackDeliveredNotification(appGroup: String, notificationData: NotificationData) {
        do {
            try DeliveredNotificationTracker(appGroup: appGroup, notificationData: notificationData)
                .track(
                    onSuccess: {
                        self.notificationTracked = true
                    },
                    onFailure: {
                        self.saveNotificationForLaterTracking(notification: notificationData)
                        self.notificationTracked = true
                    }
                )
        } catch {
            Exponea.logger.log(
                .error,
                message: "Failed to track delivered push notification: \(error.localizedDescription)"
            )
            self.saveNotificationForLaterTracking(notification: notificationData)
            self.notificationTracked = true
        }
    }

    func prepareNotificationData(request: UNNotificationRequest) -> NotificationData? {
        guard let userInfo = (request.content.mutableCopy() as? UNMutableNotificationContent)?.userInfo else {
            Exponea.logger.log(
                .error,
                message: "Failed to prepare data for delivered push notification:" +
                    " Unable to get user info object from notification."
            )
            self.notificationTracked = true
            return nil
        }

        var notificationData = NotificationData.deserialize(
            attributes: userInfo["attributes"] as? [String: Any] ?? [:],
            campaignData: userInfo["url_params"] as? [String: Any] ?? [:]
        ) ?? NotificationData()

        let timestamp = notificationData.timestamp
        let sentTimestamp = notificationData.sentTimestamp ?? 0
        let deliveredTimestamp = timestamp <= sentTimestamp ? sentTimestamp + 1 : timestamp

        notificationData.timestamp = deliveredTimestamp
        return notificationData
    }

    func checkDone() {
        if notificationTracked && contentCreated {
            if let content = bestAttemptContent {
                contentHandler?(content)
            }
            clean()
        }
    }

    func saveNotificationForLaterTracking(notification: NotificationData?) {
        guard let appGroup = appGroup,
              let userDefaults = UserDefaults(suiteName: appGroup),
              let notificationData = notification else {
            return
        }

        if let serialized = notificationData.serialize() {
            var delivered = userDefaults.array(forKey: Constants.General.deliveredPushUserDefaultsKey) ?? []
            delivered.append(serialized)
            userDefaults.set(delivered, forKey: Constants.General.deliveredPushUserDefaultsKey)
        }
    }

    func saveImage(_ identifier: String, data: Data, options: [AnyHashable: Any]?) -> UNNotificationAttachment? {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
        let directory = url.appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString, isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            let fileURL = directory.appendingPathComponent(identifier)
            try data.write(to: fileURL, options: [])
            return try UNNotificationAttachment.init(identifier: identifier, url: fileURL, options: options)
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
