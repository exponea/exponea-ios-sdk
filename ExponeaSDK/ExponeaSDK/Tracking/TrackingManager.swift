//
//  TrackingManager.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 11/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

class TrackingManager {
    let database: DatabaseManagerType
    let repository: TrackingRepository

    init(database: DatabaseManagerType, repository: TrackingRepository) {
        self.database = database
        self.repository = repository
    }
}

extension TrackingManager: TrackingManagerType {
    func trackEvent(_ type: EventType, customData: [String: Any]?) -> Bool {

        guard let projectToken = Exponea.shared.projectToken else {
            Exponea.logger.log(.error, message: Constants.ErrorMessages.tokenNotConfigured)
            return false
        }

        switch type {
        case .install:
            return installEvent(projectToken: projectToken)
        case .sessionStart:
            // TODO: save to db
            return false

        case .sessionEnd:
            // TODO: save to db
            return false

        case .event(let customerId, let properties, let timestamp, let eventType):
            return trackEvent(projectToken: projectToken,
                              customerId: customerId,
                              properties: properties,
                              timestamp: timestamp,
                              eventType: eventType)
        case .track(let customerId, let properties, let timestamp):
            return false

        case .custom(let value):
            // TODO: save to db
            return false
        }
    }
}

extension TrackingManager {
    func installEvent(projectToken: String) -> Bool {
        return database.trackInstall(projectToken: projectToken,
                                     properties: DeviceProperties().asKeyValueModel())
    }

    func trackEvent(projectToken: String,
                    customerId: KeyValueModel,
                    properties: [KeyValueModel],
                    timestamp: Double?,
                    eventType: String?) -> Bool {
        return database.trackEvents(projectToken: projectToken,
                                    customerId: customerId,
                                    properties: properties,
                                    timestamp: timestamp,
                                    eventType: eventType)
    }

    func trackProperties(projectId: String,
                         customerId: KeyValueModel,
                         properties: [KeyValueModel],
                         timestamp: Double?) -> Bool {
        return database.trackCustomer(projectToken: projectId,
                                      customerId: customerId,
                                      properties: properties,
                                      timestamp: timestamp)
    }
}
