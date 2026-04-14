//
//  ExponeaNotificationService.swift
//  ExponeaSDKNotifications
//
//  Created by Dominik Hadl on 22/11/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import UserNotifications
#if canImport(ExponeaSDKShared)
import ExponeaSDKShared
#endif

public class ExponeaNotificationService {

    private let appGroup: String?
    private var isSDKStopped: Bool {
        UserDefaults(suiteName: appGroup ?? "ExponeaSDK")?.value(forKey: "isStopped") as? Bool ?? false
    }
    internal var telemetry: TelemetryUpload?

    var request: UNNotificationRequest?
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    var notificationDeliveryTracked: Bool = false {
        didSet {
            checkDone()
        }
    }
    var deliveryTelemetryTracked: Bool = false {
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
        if let appGroup {
            let userDefaults = TelemetryUtility.getUserDefaults(appGroup: appGroup)
            let installId = TelemetryUtility.getInstallId(userDefaults: userDefaults)
            self.telemetry = SentryTelemetryUpload(installId: installId) {
                Configuration.loadFromUserDefaults(appGroup: appGroup)
            }
        } else {
            self.telemetry = nil
        }
    }

    public func process(request: UNNotificationRequest, contentHandler: @escaping (UNNotificationContent) -> Void) {
        NSLog("=== ExponeaNotificationService: process ===")
        guard Exponea.isExponeaNotification(userInfo: request.content.userInfo) else {
            Exponea.logger.log(.verbose, message: "Skipping non-Exponea notification")
            return
        }
        guard !isSDKStopped else {
            NSLog("=== ExponeaNotificationService: STOPPED ===")
            contentHandler(request.content)
            return
        }
        NSLog("=== ExponeaNotificationService: TRACKING ===")
        self.request = request
        self.contentHandler = contentHandler

        if let notificationData = prepareNotificationData(request: request),
           let appGroup = appGroup {
            trackDeliveredNotification(appGroup: appGroup, notificationData: notificationData)
            createContent(deliveredTimestamp: notificationData.timestamp)
            trackDeliveredTelemetry(
                notificationData: notificationData,
                notificationId: readNotificationId(request)
            )
        }
    }

    private func readNotificationId(_ request: UNNotificationRequest?) -> String {
        request?.identifier ?? "none"
    }

    public func serviceExtensionTimeWillExpire() {
        // Clean, after we are finished
        defer { clean() }

        // we failed to track notification
        if !notificationDeliveryTracked {
            if let userInfo = (request?.content.mutableCopy() as? UNMutableNotificationContent)?.userInfo {
            let notification = NotificationData.deserialize(
                attributes: userInfo["attributes"] as? [String: Any] ?? [:],
                campaignData: userInfo["url_params"] as? [String: Any] ?? [:],
                consentCategoryTracking: userInfo["consent_category_tracking"] as? String ?? nil,
                hasTrackingConsent: GdprTracking.readTrackingConsentFlag(userInfo["has_tracking_consent"])
            ) ?? NotificationData()
            saveNotificationForLaterTracking(notification: notification)
            }
        }
        if !deliveryTelemetryTracked {
            // we failed to track telemetry for notification delivery
            if let request,
               let notificationData = prepareNotificationData(request: request) {
                let deliveredEventLog = buildTelemetryEventLog(
                    eventType: .pushNotificationDelivered,
                    notificationData: notificationData,
                    notificationId: readNotificationId(request)
                )
                saveTelemetryEventForLater(event: deliveredEventLog)
            }
        }
        // Try to call content handler with current content
        showNotification(allowWaitForTrack: false)
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
                let url = imagePath.cleanedURL(),
                let data = try? Data(contentsOf: url, options: []),
                let attachment = saveImage("image.png", data: data, options: nil) {
                bestAttemptContent?.attachments = [attachment]
            }
        }
        contentCreated = true
    }

    func trackDeliveredNotification(appGroup: String, notificationData: NotificationData) {
        do {
            let deliveredTracker = try DeliveredNotificationTracker(appGroup: appGroup, notificationData: notificationData)
            deliveredTracker.track(
                onSuccess: {
                    self.notificationDeliveryTracked = true
                },
                onFailure: {
                    self.saveNotificationEventsForLaterTracking(deliveredTracker.events)
                    self.notificationDeliveryTracked = true
                }
            )
        } catch {
            Exponea.logger.log(
                .error,
                message: "Failed to track delivered push notification: \(error.localizedDescription)"
            )
            self.saveNotificationForLaterTracking(notification: notificationData)
            self.notificationDeliveryTracked = true
        }
    }

    private func trackDeliveredTelemetry(notificationData: NotificationData, notificationId: String) {
        let deliveredEventLog = buildTelemetryEventLog(
            eventType: .pushNotificationDelivered,
            notificationData: notificationData,
            notificationId: notificationId
        )
        guard let telemetry = self.telemetry else {
            self.saveTelemetryEventForLater(event: deliveredEventLog)
            self.deliveryTelemetryTracked = true
            return
        }
        telemetry.upload(eventLog: deliveredEventLog, completionHandler: { telemetryTracked in
            if !telemetryTracked {
                self.saveTelemetryEventForLater(event: deliveredEventLog)
            }
            self.deliveryTelemetryTracked = true
        })
    }
    
    private func trackShownTelemetry(_ done: @escaping () -> ()) {
        guard
            let request = self.request,
            let notificationData = prepareNotificationData(request: request) else {
            done()
            return
        }
        let shownEventLog = buildTelemetryEventLog(
            eventType: .pushNotificationShown,
            notificationData: notificationData,
            notificationId: readNotificationId(request)
        )
        guard let telemetry = self.telemetry else {
            self.saveTelemetryEventForLater(event: shownEventLog)
            done()
            return
        }
        telemetry.upload(eventLog: shownEventLog) { telemetryTracked in
            if !telemetryTracked {
                self.saveTelemetryEventForLater(event: shownEventLog)
            }
            done()
        }
    }
    
    private func buildTelemetryEventLog(eventType: TelemetryEventType, notificationData: NotificationData, notificationId: String) -> EventLog {
        return EventLog(
            name: eventType.rawValue,
            runId: UUID().uuidString,
            properties: [
                "notificationId": notificationId,
                "actionId": TelemetryUtility.readAsString(notificationData.properties["action_id"]?.rawValue),
                "campaignId": TelemetryUtility.readAsString(notificationData.properties["campaign_id"]?.rawValue)
            ]
        )
    }

    func prepareNotificationData(request: UNNotificationRequest) -> NotificationData? {
        guard let userInfo = (request.content.mutableCopy() as? UNMutableNotificationContent)?.userInfo else {
            Exponea.logger.log(
                .error,
                message: "Failed to prepare data for delivered push notification:" +
                    " Unable to get user info object from notification."
            )
            self.notificationDeliveryTracked = true
            return nil
        }

        var notificationData = NotificationData.deserialize(
            attributes: userInfo["attributes"] as? [String: Any] ?? [:],
            campaignData: userInfo["url_params"] as? [String: Any] ?? [:],
            consentCategoryTracking: userInfo["consent_category_tracking"] as? String ?? nil,
            hasTrackingConsent: GdprTracking.readTrackingConsentFlag(userInfo["has_tracking_consent"])
        ) ?? NotificationData()

        let timestamp = notificationData.timestamp
        let sentTimestamp = notificationData.sentTimestamp ?? 0
        let deliveredTimestamp = timestamp <= sentTimestamp ? sentTimestamp + 1 : timestamp

        notificationData.timestamp = deliveredTimestamp
        return notificationData
    }

    func checkDone() {
        if notificationDeliveryTracked && contentCreated && deliveryTelemetryTracked {
            showNotification(allowWaitForTrack: true)
            clean()
        }
    }
    
    private func showNotification(allowWaitForTrack: Bool) {
        guard let content = bestAttemptContent else {
            Exponea.logger.log(.error, message: "Notification content has not been build for show")
            return
        }
        if allowWaitForTrack {
            // keep contentHandler locally to avoid reset in clean()
            let contentHandlerLocal = contentHandler
            trackShownTelemetry {
                contentHandlerLocal?(content)
            }
        } else {
            // try track telemetry, it could not be finished, but ensure that contentHandler is called
            trackShownTelemetry {}
            contentHandler?(content)
        }
    }
    
    func saveTelemetryEventForLater(event: EventLog) {
        guard let userDefaults = UserDefaults(suiteName: appGroup) else {
            Exponea.logger.log(.error, message: "Unable to store telemetry data")
            return
        }
        var telemetryEvents = TelemetryUtility.readTelemetryEvents(userDefaults)
        telemetryEvents.append(event)
        TelemetryUtility.saveTelemetryEvents(userDefaults, telemetryEvents)
    }

    func saveNotificationForLaterTracking(notification: NotificationData?) {
        guard let appGroup = appGroup,
              let userDefaults = UserDefaults(suiteName: appGroup),
              let notificationData = notification,
              let serialized = notificationData.serialize() else {
            Exponea.logger.log(.error, message: "Unable to store delivered notification data")
            return
        }
        var delivered = userDefaults.array(forKey: Constants.General.deliveredPushUserDefaultsKey) ?? []
        delivered.append(serialized)
        userDefaults.set(delivered, forKey: Constants.General.deliveredPushUserDefaultsKey)
    }

    func saveNotificationEventsForLaterTracking(_ events: [EventTrackingObject]) {
        guard let appGroup = appGroup,
              let userDefaults = UserDefaults(suiteName: appGroup) else {
            Exponea.logger.log(.error, message: "Unable to store delivery notification tracking events")
            return
        }
        var deliveredNotifEvents = userDefaults.array(forKey: Constants.General.deliveredPushEventUserDefaultsKey) ?? []
        for each in events {
            guard let trackingData = each.serialize() else {
                Exponea.logger.log(.error, message: "Unable to store delivery notification tracking event")
                continue
            }
            deliveredNotifEvents.append(trackingData)
        }
        userDefaults.set(deliveredNotifEvents, forKey: Constants.General.deliveredPushEventUserDefaultsKey)
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
