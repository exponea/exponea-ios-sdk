//
//  ExponeaNotificationService.swift
//  ExponeaSDKNotifications
//
//  Created by Dominik Hadl on 22/11/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import UserNotifications
import ExponeaSDKShared

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

        trackDeliveredNotification()
        createContent()
    }

    public func serviceExtensionTimeWillExpire() {
        // Clean, after we are finished
        defer { clean() }

        // we failed to track notification
        if !notificationTracked {
            saveNotificationForLaterTracking(request: request)
        }

        // Try to call content handler with current content
        if let content = bestAttemptContent {
            contentHandler?(content)
        }
    }

    internal func createContent() {
        // Create a mutable content and make sure it works
        bestAttemptContent = (request?.content.mutableCopy() as? UNMutableNotificationContent)

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

    func trackDeliveredNotification() {
        guard let appGroup = appGroup, let request = request else {
            notificationTracked = true
            return
        }
        do {
            try DeliveredNotificationTracker(appGroup: appGroup, request: request)
                .track(
                    onSuccess: {
                        self.notificationTracked = true
                    },
                    onFailure: {
                        self.saveNotificationForLaterTracking(request: request)
                        self.notificationTracked = true
                    }
                )
        } catch {
            Exponea.logger.log(
                .error,
                message: "Failed to track delivered push notification: \(error.localizedDescription)"
            )
            self.saveNotificationForLaterTracking(request: request)
            self.notificationTracked = true
        }
    }

    func checkDone() {
        if notificationTracked && contentCreated {
            if let content = bestAttemptContent {
                contentHandler?(content)
            }
            clean()
        }
    }

    func saveNotificationForLaterTracking(request: UNNotificationRequest?) {
        guard let appGroup = appGroup,
              let userDefaults = UserDefaults(suiteName: appGroup),
              let userInfo = request?.content.userInfo else {
            return
        }
        let notification = NotificationData.deserialize(
            attributes: userInfo["attributes"] as? [String: Any] ?? [:],
            campaignData: userInfo["url_params"] as? [String: Any] ?? [:]
        ) ?? NotificationData()

        if let serialized = notification.serialize() {
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
