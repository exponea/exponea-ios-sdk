//
//  SessionManager.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 23/03/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation

final class SessionManager: SessionManagerType {
    private let userDefaults: UserDefaults
    private let isAutomatic: Bool
    private let sessionTimeout: Double
    private weak var trackingDelegate: SessionTrackingDelegate?

    var sessionStartTime: Double {
        get { return userDefaults.double(forKey: Constants.Keys.sessionStarted) }
        set { userDefaults.set(newValue, forKey: Constants.Keys.sessionStarted) }
    }

    var sessionEndTime: Double {
        get { return userDefaults.double(forKey: Constants.Keys.sessionEnded) }
        set { userDefaults.set(newValue, forKey: Constants.Keys.sessionEnded) }
    }

    var hasActiveSession: Bool { return sessionStartTime != 0 }

    init(
        configuration: Configuration,
        userDefaults: UserDefaults,
        trackingDelegate: SessionTrackingDelegate
    ) {
        self.userDefaults = userDefaults
        self.trackingDelegate = trackingDelegate
        self.sessionTimeout = configuration.sessionTimeout
        self.isAutomatic = configuration.automaticSessionTracking
    }

    func manualSessionStart(at timestamp: TimeInterval) {
        guard !isAutomatic else { return }
        triggerSessionStart(at: timestamp)
    }

    func manualSessionEnd(at timestamp: TimeInterval) {
        guard !isAutomatic else { return }
        sessionEndTime = timestamp
        triggerSessionEnd(at: timestamp)
    }

    func ensureSessionStarted(at timestamp: TimeInterval) {
        guard isAutomatic else { return }
        if !hasActiveSession {
            Exponea.logger.log(.verbose, message: "Manually triggering session start")
            triggerSessionStart(at: timestamp)
        }
    }

    func applicationDidBecomeActive(at timestamp: TimeInterval) {
        guard isAutomatic else { return }
        triggerSessionStart(at: timestamp)
    }

    func applicationDidEnterBackground(at timestamp: TimeInterval) {
        guard isAutomatic else { return }
        sessionEndTime = timestamp
    }

    func doSessionTimeoutBackgroundWork(at timestamp: TimeInterval) {
        guard isAutomatic else { return }
        triggerSessionEnd(at: timestamp)
    }

    func clear() {
        sessionStartTime = 0
        sessionEndTime = 0
    }

    private func shouldResumeCurrentSession(at timestamp: TimeInterval) -> Bool {
        guard hasActiveSession else {
            return false
        }
        if sessionEndTime != 0 {
            // when sessionEndTime is available, check if it times out in the future
            return sessionEndTime + sessionTimeout > timestamp
        } else {
            // otherwise(app was terminated), check time from session start
            return sessionStartTime + sessionTimeout > timestamp
        }
    }

    private func triggerSessionStart(at timestamp: TimeInterval) {
        // if previous session was not closed properly(background work was not run)
        if hasActiveSession {
            if !shouldResumeCurrentSession(at: timestamp) {
                Exponea.logger.log(.verbose, message: "We're past session timeout, tracking previous session end.")
                triggerSessionEnd(at: timestamp)
            } else {
                Exponea.logger.log(.verbose, message: "Continuing current session as we're within session timeout.")
                return
            }
        }
        sessionStartTime = timestamp
        trackingDelegate?.trackSessionStart(at: sessionStartTime)
        Exponea.logger.log(.verbose, message: Constants.SuccessMessages.sessionStart)
    }

    private func triggerSessionEnd(at timestamp: TimeInterval) {
        guard sessionStartTime != 0 else {
            Exponea.logger.log(.error, message: "Can't end session as no session was started.")
            return
        }
        // Only use current time if app backgrounded time is not available
        sessionEndTime = sessionEndTime == 0 ? timestamp : sessionEndTime

        trackingDelegate?.trackSessionEnd(at: sessionEndTime, withDuration: sessionEndTime - sessionStartTime)

        // Reset session times
        sessionStartTime = 0
        sessionEndTime = 0

        Exponea.logger.log(.verbose, message: Constants.SuccessMessages.sessionEnd)
    }
}
