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
    let device: DeviceProperties
    var configuration: Configuration

    /// Used for periodic data flushing
    var flushingTimer: Timer?
    var flushingMode: FlushingMode = .automatic {
        didSet {
            updateFlushingMode()
        }
    }

    init(database: DatabaseManagerType, repository: TrackingRepository, configuration: Configuration) {
        self.database = database
        self.repository = repository
        self.configuration = configuration
        self.device = DeviceProperties()
    }
}

// MARK: - Flushing -

extension TrackingManager {
    @objc func flushData() {
        // TODO: Data flushing
        // 1. check if data to flush
        // 2. pull from db
        // 3. run upload
        // 4a. on fail, return to step 2
        // 4b. on success, delete from db

        // Pull from db
        let events = database.fetchTrackEvents()
        let customers = database.fetchTrackCustomer()

        // Check if we have any data, otherwise bail
        guard !events.isEmpty || !customers.isEmpty else {
            return
        }

//        for event in events {
//
//        }
//
//        for customer in customers {
//
//        }
    }

    func updateFlushingMode() {
        // Invalidate timers
        flushingTimer?.invalidate()
        flushingTimer = nil

        // Remove observers
        let center = NotificationCenter.default
        center.removeObserver(self, name: Notification.Name.UIApplicationWillResignActive, object: nil)

        // Update for new flushing mode
        switch flushingMode {
        case .manual: break
        case .automatic:
            // Automatically upload on resign active
            let center = NotificationCenter.default
            center.addObserver(self, selector: #selector(flushData),
                               name: Notification.Name.UIApplicationWillResignActive, object: nil)

        case .periodic(let interval):
            // Schedule a timer for the specified interval
            flushingTimer = Timer(timeInterval: TimeInterval(interval), target: self,
                                  selector: #selector(flushData), userInfo: nil, repeats: true)
        }
    }
}

extension TrackingManager: TrackingManagerType {
    func trackEvent(_ type: EventType, customData: [DataType]?) -> Bool {

        guard let projectToken = Exponea.shared.projectToken else {
            Exponea.logger.log(.error, message: Constants.ErrorMessages.tokenNotConfigured)
            return false
        }

        let data: [DataType] = [.projectToken(projectToken)] + (customData ?? [])

        switch type {
        case .install:
            return installEvent(projectToken: projectToken)
        case .sessionStart:
            return sessionStart(projectToken: projectToken)
        case .sessionEnd:
            // TODO: save to db
            return false
        case .trackEvent:
            return trackEvent(with: data)
        case .trackCustomer:
            return trackCustomer(with: data)
        case .payment:
            return trackPayment(with: data + [.eventType(Constants.EventTypes.payment)])
        }
    }
}

extension TrackingManager {
    func installEvent(projectToken: String) -> Bool {
        return database.trackEvent(with: [.projectToken(projectToken),
                                          .properties(device.properties),
                                          .eventType(Constants.EventTypes.installation)])
    }

    func trackEvent(with data: [DataType]) -> Bool {
        return database.trackEvent(with: data)
    }

    func trackCustomer(with data: [DataType]) -> Bool {
        return database.trackCustomer(with: data)
    }

    func trackPayment(with data: [DataType]) -> Bool {
        return database.trackEvent(with: data)
    }

    func sessionStart(projectToken: String) -> Bool {
        /// Get the current timestamp to calculate the session period.
        let now = Date().timeIntervalSince1970
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
        var properties = device.properties
        /// Adding session start properties.
        properties.append(KeyValueModel(key: "event_type", value: Constants.EventTypes.sessionStart))
        properties.append(KeyValueModel(key: "timestamp", value: configuration.lastSessionStarted))

        if let appVersion = Bundle.main.value(forKey: Constants.Keys.appVersion) {
            properties.append(KeyValueModel(key: "app_version", value: appVersion))
        }
        return database.trackEvent(with: [.projectToken(projectToken),
                                          .properties(properties),
                                          .eventType(Constants.EventTypes.sessionStart)])
    }

    fileprivate func trackEndSession(projectToken: String) -> Bool {
        /// Prepare data to persist into coredata.
        var properties = device.properties
        /// Calculate the duration of the last session.
        let duration = configuration.lastSessionStarted - configuration.lastSessionEndend
        /// Adding session end properties.
        properties.append(KeyValueModel(key: "event_type", value: Constants.EventTypes.sessionStart))
        properties.append(KeyValueModel(key: "timestamp", value: configuration.lastSessionEndend))
        properties.append(KeyValueModel(key: "duration", value: duration))

        if let appVersion = Bundle.main.value(forKey: Constants.Keys.appVersion) {
            properties.append(KeyValueModel(key: "app_version", value: appVersion))
        }
        return database.trackEvent(with: [.projectToken(projectToken),
                                          .properties(properties),
                                          .eventType(Constants.EventTypes.sessionEnd)])
    }
}
