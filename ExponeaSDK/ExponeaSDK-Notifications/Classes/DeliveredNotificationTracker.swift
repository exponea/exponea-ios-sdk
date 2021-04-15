//
//  DeliveredNotificationTracker.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 09/03/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation
import UserNotifications
#if !COCOAPODS
import ExponeaSDKShared
#endif

final class DeliveredNotificationTracker {
    private let events: [EventTrackingObject]
    private let repository: ServerRepository

    init(appGroup: String, notificationData: NotificationData) throws {
        guard let configuration = Configuration.loadFromUserDefaults(appGroup: appGroup) else {
            throw DeliveredNotificationTrackerError.configurationNotFound
        }
        guard let customerIds = EventTrackingObject.loadCustomerIdsFromUserDefaults(appGroup: appGroup) else {
            throw DeliveredNotificationTrackerError.customerIdsNotFound
        }
        repository = ServerRepository(configuration: configuration)
        events = DeliveredNotificationTracker.generateTrackingObjects(
            configuration: configuration,
            customerIds: customerIds,
            notification: notificationData
        )
    }

    func track(onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void) {
        guard events.count > 0 else {
            onSuccess()
            return
        }
        var remainingRequests = events.count
        var failedRequests = 0
        events.forEach { event in
            repository.trackObject(event) { result in
                if case .failure(let error) = result {
                    Exponea.logger.log(.error, message: "Failed to upload push delivered event \(error)")
                    failedRequests += 1
                }
                remainingRequests -= 1
                if remainingRequests == 0 {
                    if failedRequests == 0 {
                        onSuccess()
                    } else {
                        onFailure()
                    }
                }
            }
        }
    }

    static func generateTrackingObjects(
        configuration: Configuration,
        customerIds: [String: String],
        notification: NotificationData
    ) -> [EventTrackingObject] {
        var properties = configuration.defaultProperties?.mapValues { $0.jsonValue } ?? [:]
        properties = properties.merging(notification.properties, uniquingKeysWith: { (_, new) in new })
        properties["status"] = .string("delivered")

        let eventType = notification.eventType != nil ? EventType.customEvent : EventType.pushDelivered
        let projects = configuration.projects(for: eventType)
        return projects.map { project in
            return EventTrackingObject(
                exponeaProject: project,
                customerIds: customerIds,
                eventType: notification.eventType ?? Constants.EventTypes.pushDelivered,
                timestamp: notification.timestamp,
                dataTypes: [.properties(properties)]
            )
        }
    }
}

enum DeliveredNotificationTrackerError: LocalizedError {
    case unableToGetUserInfo
    case configurationNotFound
    case customerIdsNotFound

    public var errorDescription: String? {
        switch self {
        case .unableToGetUserInfo: return "Unable to get user info object from notification."
        case .configurationNotFound: return "Cannot get configuration object from UserDefaults."
        case .customerIdsNotFound: return "Cannot get customer ids object from UserDefaults."
        }
    }
}
