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
    var configuration: Configuration

    init(database: DatabaseManagerType, repository: TrackingRepository, configuration: Configuration) {
        self.database = database
        self.repository = repository
        self.configuration = configuration
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
            return sessionStart(projectToken: projectToken)
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
        return database.trackEvents(type: Constants.EventTypes.installation,
                                    projectToken: projectToken,
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

    func sessionStart(projectToken: String) -> Bool {
        /// Get the current timestamp to calculate the session period.
        let now = NSDate().timeIntervalSince1970
        /// Check the status of the previous session.
        if sessionEnded(newTimestamp: now, projectToken: projectToken) {
            /// Update the new session value.
            configuration.lastSessionStarted = now
            guard trackEndSession(projectToken: projectToken) else {
                Exponea.logger.log(.error, message: Constants.ErrorMessages.couldNotEndSession)
                return false
            }
            guard trackStartSession(projectToken: projectToken) else {
                Exponea.logger.log(.error, message: Constants.ErrorMessages.couldNotStartSession)
                return false
            }
            return true
        } else {
            configuration.lastSessionStarted = now
            return trackStartSession(projectToken: projectToken)
        }
    }
}

extension TrackingManager {
    fileprivate func sessionEnded(newTimestamp: Double, projectToken: String) -> Bool {
        /// Check only if session has ended before.
        guard configuration.lastSessionEndend > 0 else {
            return false
        }
        /// Calculate the session duration.
        let sessionDuration = newTimestamp - configuration.lastSessionEndend
        /// Session should be ended.
        if sessionDuration > Exponea.shared.sessionTimeout {
            return true
        } else {
            return false
        }
    }

    fileprivate func trackStartSession(projectToken: String) -> Bool {
        /// Prepare data to persist into coredata.
        var properties = DeviceProperties().asKeyValueModel()
        /// Adding session start properties.
        properties.append(KeyValueModel(key: "session_start", value: configuration.lastSessionStarted))

        if let appVersion = Bundle.main.value(forKey: Constants.Keys.appVersion) {
            properties.append(KeyValueModel(key: "app_version", value: appVersion))
        }
        return database.trackEvents(type: Constants.EventTypes.sessionStart,
                                    projectToken: projectToken,
                                    properties: properties)
    }

    fileprivate func trackEndSession(projectToken: String) -> Bool {
        /// Prepare data to persist into coredata.
        var properties = DeviceProperties().asKeyValueModel()
        /// Calculate the duration of the last session.
        let duration = configuration.lastSessionStarted - configuration.lastSessionEndend
        /// Adding session end properties.
        properties.append(KeyValueModel(key: "duration", value: duration))
        properties.append(KeyValueModel(key: "session_end", value: configuration.lastSessionEndend))

        if let appVersion = Bundle.main.value(forKey: Constants.Keys.appVersion) {
            properties.append(KeyValueModel(key: "app_version", value: appVersion))
        }
        return database.trackEvents(type: Constants.EventTypes.sessionEnd,
                                    projectToken: projectToken,
                                    properties: properties)
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
