//
//  PushNotificationManager.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 25/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import UserNotifications
import UIKit
#if canImport(ExponeaSDKShared)
import ExponeaSDKShared
#endif

public protocol PushNotificationManagerDelegate: AnyObject {

    func pushNotificationOpened(
        with action: ExponeaNotificationActionType,
        value: String?,
        extraData: [AnyHashable: Any]?
    )

    func silentPushNotificationReceived(extraData: [AnyHashable: Any]?)
}

public extension PushNotificationManagerDelegate {
    // default implementation is empty for compatibility
    func silentPushNotificationReceived(extraData: [AnyHashable: Any]?) {}
}

public struct PushTokenType {
    var pushToken: String
    var isTokenValid: Bool
}

final class PushNotificationManager: NSObject, PushNotificationManagerType {
    /// The tracking manager used to track push events
    internal var trackingConsentManager: TrackingConsentManagerType
    internal var trackingManager: TrackingManagerType

    private let requirePushAuthorization: Bool
    private let appGroup: String? // used for sharing data across extensions, fx. for push delivered tracking
    private let tokenTrackFrequency: TokenTrackFrequency
    private let urlOpener: UrlOpenerType
    private var currentPushToken: PushTokenType?
    private var lastKnownPushToken: PushTokenType?
    private var lastTokenTrackDate: Date
    private var pushNotificationSwizzler: PushNotificationSwizzler?
    private let userDefaults: UserDefaults?
    private var isFirstNotificationStateTracking: Bool
    private let appVersion: String?
    private let currentApplicationID: String?
    /// Last successful `notification_state` track's OS push-authorization flag. `nil`
    /// means "never persisted" — distinguishable from a persisted `false` so the very
    /// first denied → granted (or granted → denied) flip after install is not silenced
    /// by `bool(forKey:)`'s missing-key collapse. Hydrated from `UserDefaults` in
    /// `init` and refreshed inside `trackCurrentPushToken`'s success path.
    private var lastPermissionFlag: Bool?
    /// Ensures `.everyLaunch` emits a single `notification_state` per process session.
    private var hasTrackedThisSession = false
    /// Serial queue for notification state and frequency checks to avoid races from auth callbacks.
    private let stateQueue = DispatchQueue(label: "com.exponea.pushNotificationManager.state")

    // some push notification can be received before the delegate is set, we'll store them and call delegate once set
    internal var pendingOpenedPushes: [PushOpenedData] = []
    private weak var delegateValue: PushNotificationManagerDelegate?
    internal var delegate: PushNotificationManagerDelegate? {
        get {
            return delegateValue
        }
        set {
            delegateValue = newValue
            guard let delegateValue = delegateValue else {
                return
            }
            pendingOpenedPushes.forEach {
                if $0.silent {
                    delegateValue.silentPushNotificationReceived(extraData: $0.extraData)
                } else {
                    delegateValue.pushNotificationOpened(
                        with: $0.actionType,
                        value: $0.actionValue,
                        extraData: $0.extraData
                    )
                }
            }
            pendingOpenedPushes = []
        }
    }

    var didReceiveSelfPushCheck: Bool = false

    let decoder: JSONDecoder = JSONDecoder.snakeCase

    init(
        trackingConsentManager: TrackingConsentManagerType,
        trackingManager: TrackingManagerType,
        swizzlingEnabled: Bool,
        requirePushAuthorization: Bool,
        appGroup: String?,
        tokenTrackFrequency: TokenTrackFrequency,
        currentPushToken: String?,
        lastTokenTrackDate: Date?,
        urlOpener: UrlOpenerType,
        userDefaults: UserDefaults? = UserDefaults(suiteName: Constants.General.userDefaultsSuite),
        currentAppVersion: String? = Bundle.main.infoDictionary?[Constants.Keys.appVersion] as? String,
        currentApplicationID: String? = nil
    ) {
        self.appGroup = appGroup
        self.trackingConsentManager = trackingConsentManager
        self.trackingManager = trackingManager
        self.tokenTrackFrequency = tokenTrackFrequency
        self.userDefaults = userDefaults
        self.currentApplicationID = currentApplicationID

        if let currentPushToken {
            let newToken = PushTokenType(
                pushToken: currentPushToken,
                isTokenValid: true
            )
            self.currentPushToken = newToken
            self.lastKnownPushToken = newToken
        }
        // appVersion is typically CFBundleShortVersionString (Constants.Keys.appVersion); used to force notification_state on version change.
        self.appVersion = currentAppVersion
        let hasTracked = userDefaults?.bool(forKey: Constants.General.notificationStateTracked) ?? false
        let storedAppVersion = userDefaults?.string(forKey: Constants.General.notificationStateAppVersion)
        let storedApplicationID = userDefaults?.string(forKey: Constants.General.notificationStateApplicationID)
        // Tri-state read: `object(forKey:)` returns nil when the key was never written,
        // which is the signal `.onTokenChange` needs to suppress a spurious "permission
        // changed" emission on the very first launch (no baseline to compare against).
        self.lastPermissionFlag = userDefaults?.object(forKey: Constants.General.notificationStateLastPermissionFlag) as? Bool
        
        // appVersionChanged is true when:
        //   • hasTracked = true (flag exists) AND
        //   • we have a readable bundle version AND
        //   • it differs from the stored one (including nil → means first run of this new code)
        let appVersionChanged = hasTracked && currentAppVersion != nil && currentAppVersion != storedAppVersion
        
        // applicationIDChanged is true when we have tracked before and the application ID differs from the stored one
        let applicationIDChanged = hasTracked && currentApplicationID != nil && currentApplicationID != storedApplicationID
        
        let shouldForceTracking = !hasTracked || appVersionChanged || applicationIDChanged
        
        self.lastTokenTrackDate = shouldForceTracking ? .distantPast : (lastTokenTrackDate ?? .distantPast)
        self.isFirstNotificationStateTracking = shouldForceTracking
        
        self.urlOpener = urlOpener
        self.requirePushAuthorization = requirePushAuthorization
        
        super.init()

        if swizzlingEnabled {
            pushNotificationSwizzler = PushNotificationSwizzler(self)
            pushNotificationSwizzler?.addAutomaticPushTracking()
        }
        // Refresh the shared DeliveryAuthorizationProvider snapshot before
        // consuming any stored delivered pushes. TrackingConsentManager.trackDeliveredPush
        // runs synchronously and cannot afford to block on
        // getNotificationSettings; it reads `lastSnapshot` instead. Chaining
        // the consume off `refresh(completion:)` guarantees the synchronous
        // read sees the just-refreshed snapshot rather than the pre-refresh
        // one — without this, the first delivered event after a cold start
        // would be resolved against whatever (possibly stale) snapshot
        // happened to be cached by the prior process.
        //
        // The real UNUserNotificationCenter-backed provider is installed by
        // ExponeaInternal.sharedInitializer on production configure; test
        // bundles keep the NoopProvider default (NoopProvider fires the
        // completion synchronously with `nil`, preserving the original
        // call ordering in specs that don't substitute their own provider).
        DeliveryAuthorizationProvider.refresh { [weak self] in
            self?.checkForDeliveredPushMessages()
        }
        processStoredPushOpens()
        verifyPushStatusAndTrackPushToken()
        // Crash-survival drain. If a pre-init APNs token
        // was persisted by `Exponea.shared.handlePushNotificationToken`
        // and the process crashed before `configure()` completed, the
        // in-memory `ExpoInitManager.actionBlocks` queue was lost; the
        // persisted buffer covers that gap. In the happy path the
        // action-block also fires, but the second call is deduplicated
        // by `handlePushTokenRegisteredUnsafe`'s currentPushToken check,
        // so no duplicate `notification_state` is emitted.
        //
        // Ordering: drain runs AFTER `verifyPushStatusAndTrackPushToken()`,
        // not before, so the verify path uses whatever token CoreData
        // already has (typically nil on a true crash-recovery launch and
        // last-known-good on a warm reconfigure). Replaying earlier would
        // synthesize a `currentPushToken` that verify would then re-emit,
        // producing a duplicate `notification_state` on top of the one
        // `handlePushTokenRegisteredUnsafe` will emit from inside the
        // drain. With drain-after-verify, the buffered token is the
        // single source of truth for the post-init track and dedup
        // collapses any redundant call from `ExpoInitManager.actionBlocks`.
        drainPreInitTokenBufferIfNeeded()

        // We need to register for silent push notifications, but let's only do it when visible pushes are allowed
        // so we don't track push token to exponea without permission to show
        // push notifications unless enabled by developer in configuration
        if requirePushAuthorization {
            UNAuthorizationStatusProvider.current.isAuthorized { authorized in
                if authorized {
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        IntegrationManager.shared.onIntegrationStoppedCallbacks.append { [weak self] in
            guard let self else { return }
            self.pushNotificationSwizzler?.removeAutomaticPushTracking()
            NotificationCenter.default.removeObserver(
                self,
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )
        }
    }

    deinit {
        pushNotificationSwizzler?.removeAutomaticPushTracking()
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    // MARK: App lifecycle
    @objc internal func applicationDidBecomeActive() {
        Exponea.shared.executeSafely {
            self.applicationDidBecomeActiveUnsafe()
        }
    }

    // MARK: - Actions -

    func handlePushOpened(userInfoObject: AnyObject?, actionIdentifier: String?) {
        Exponea.shared.executeSafely {
            self.handlePushOpenedUnsafe(
                userInfoObject: userInfoObject,
                actionIdentifier: actionIdentifier,
                timestamp: Date().timeIntervalSince1970,
                considerConsent: true
            )
        }
    }

    func handlePushOpenedWithoutTrackingConsent(userInfoObject: AnyObject?, actionIdentifier: String?) {
        Exponea.shared.executeSafely {
            self.handlePushOpenedUnsafe(
                userInfoObject: userInfoObject,
                actionIdentifier: actionIdentifier,
                timestamp: Date().timeIntervalSince1970,
                considerConsent: false
            )
        }
    }

    func handlePushOpenedUnsafe(userInfoObject: AnyObject?,
                                actionIdentifier: String?,
                                timestamp: Double,
                                considerConsent: Bool) {
        guard let pushOpenedData = PushNotificationParser.parsePushOpened(
            userInfoObject: userInfoObject,
            actionIdentifier: actionIdentifier,
            timestamp: timestamp,
            considerConsent: considerConsent
        ) else {
            return
        }
        handlePushOpenedUnsafe(pushOpenedData: pushOpenedData)
    }

    func handlePushOpenedUnsafe(pushOpenedData: PushOpenedData) {
        if case .selfCheck = pushOpenedData.actionType {
            didReceiveSelfPushCheck = true
            return
        }
        trackingConsentManager.trackClickedPush(data: pushOpenedData)
        if pushOpenedData.silent {
            if let delegate = delegate {
                delegate.silentPushNotificationReceived(extraData: pushOpenedData.extraData)
            } else {
                pendingOpenedPushes.append(pushOpenedData)
            }
        } else {
            if pushOpenedData.considerConsent
                && !pushOpenedData.hasTrackingConsent
                && !GdprTracking.isTrackForced(pushOpenedData.actionValue)
             {
                Exponea.logger.log(.verbose, message: "Campaign data for delivered notification are not tracked because consent is not given")
            } else {
                // save campaign to be added to session start
                Exponea.shared.trackCampaignData(data: pushOpenedData.campaignData, timestamp: nil)
            }

            // Notify the delegate
            if let delegate = delegate {
                delegate.pushNotificationOpened(
                    with: pushOpenedData.actionType,
                    value: pushOpenedData.actionValue,
                    extraData: pushOpenedData.extraData
                )
            } else {
                pendingOpenedPushes.append(pushOpenedData)
            }

            switch pushOpenedData.actionType {
            case .none, .openApp, .selfCheck:
                // No need to do anything, app was opened automatically
                break

            case .browser:
                if let value = pushOpenedData.actionValue {
                    onMain { [weak self] in
                        self?.urlOpener.openBrowserLink(value)
                    }
                }

            case .deeplink:
                if let value = pushOpenedData.actionValue {
                    onMain { [weak self] in
                        self?.urlOpener.openDeeplink(value)
                    }
                }
            }
        }
    }

    /// Reads and clears any APNs token persisted by
    /// `PreInitTokenBuffer` before `configure()` completed, then replays
    /// it through the standard token-registration path. No-op when the
    /// buffer is empty.
    private func drainPreInitTokenBufferIfNeeded() {
        guard let entry = PreInitTokenBuffer.shared.drain() else {
            return
        }
        Exponea.logger.log(
            .verbose,
            message: "Replaying persisted pre-init APNs token (receivedAt=\(entry.receivedAt))."
        )
        handlePushTokenRegistered(token: entry.token)
    }

    func handlePushTokenRegistered(dataObject: AnyObject?) {
        guard let tokenData = dataObject as? Data else {
            return
        }
        Exponea.shared.executeSafely {
            self.handlePushTokenRegisteredUnsafe(token: tokenData.tokenString)
        }
    }

    func handlePushTokenRegistered(token: String) {
        Exponea.shared.executeSafely {
            self.handlePushTokenRegisteredUnsafe(token: token)
        }
    }

    private func handlePushTokenRegisteredUnsafe(token: String) {
        Exponea.shared.executeSafely {
            UNAuthorizationStatusProvider.current.isAuthorized { [weak self] authorized in
                guard let self else { return }
                Exponea.shared.executeSafely {
                    self.stateQueue.sync {
                        if let current = self.currentPushToken?.pushToken,
                           current != token {
                            self.trackCurrentPushToken(isAuthorized: authorized, isCancelled: true)
                            self.setPushTokenType(token: token, authorized: authorized)
                            self.trackCurrentPushToken(isAuthorized: authorized, isCancelled: false, onSuccess: { [weak self] in
                                self?.commitNotificationStateBaseline()
                            })
                        } else if self.currentPushToken?.pushToken == nil {
                            self.setPushTokenType(token: token, authorized: authorized)
                            self.trackCurrentPushToken(isAuthorized: authorized, isCancelled: false, onSuccess: { [weak self] in
                                self?.commitNotificationStateBaseline()
                            })
                        } else {
                            self.setPushTokenType(token: token, authorized: authorized)
                            self.checkForPushTokenFrequency(isAuthorized: authorized)
                        }
                    }
                }
            }
        }
    }
    
    private func setPushTokenType(token: String, authorized: Bool) {
        // `isTokenValid` reflects the OS push-authorization state, not the integrator's
        // `requirePushAuthorization` configuration choice. The latter governs *whether*
        // to track on this entry path (already enforced one level up); it must not
        // distort *what* the wire payload says about the token's deliverability —
        // otherwise SDK-initiated re-emissions on the cold-start / first-token path
        // can emit the contradictory pair `valid=true` + `description="Permission denied"`
        // when the integrator opted out of authorization gating but the OS still denies
        // delivery. Same fix shape as the anonymize-path correction in TrackingManager.
        let pushTokenType = PushTokenType(
            pushToken: token,
            isTokenValid: authorized
        )
        self.lastKnownPushToken = pushTokenType
        self.currentPushToken = pushTokenType
    }

    static func storePushOpened(userInfoObject: AnyObject?,
                                actionIdentifier: String?,
                                timestamp: Double,
                                considerConsent: Bool) {
        guard let userDefaults = UserDefaults(suiteName: Constants.General.userDefaultsSuite),
              let pushOpenedData = PushNotificationParser.parsePushOpened(
                  userInfoObject: userInfoObject,
                  actionIdentifier: actionIdentifier,
                  timestamp: timestamp,
                  considerConsent: considerConsent
              ) else {
            return
        }
        if let serialized = pushOpenedData.serialize() {
            var opened = userDefaults.array(forKey: Constants.General.openedPushUserDefaultsKey) ?? []
            opened.append(serialized)
            userDefaults.set(opened, forKey: Constants.General.openedPushUserDefaultsKey)
        }
    }

    func processStoredPushOpens() {
        let userDefaults = UserDefaults(suiteName: Constants.General.userDefaultsSuite)
        guard let array = userDefaults?.array(forKey: Constants.General.openedPushUserDefaultsKey) else {
            Exponea.logger.log(.verbose, message: "No opened push to track present in UserDefaults.")
            return
        }

        guard let dataArray = array as? [Data] else {
            Exponea.logger.log(.warning, message: "Opened push data present in shared group but incorrect type.")
            return
        }

        for data in dataArray {
            guard let pushOpenedData = PushOpenedData.deserialize(from: data) else {
                Exponea.logger.log(.warning, message: "Cannot deserialize stored opened push data.")
                continue
            }
            Exponea.logger.log(.verbose, message: "Handling saved opened push notification.")
            handlePushOpenedUnsafe(pushOpenedData: pushOpenedData)
        }
        userDefaults?.removeObject(forKey: Constants.General.openedPushUserDefaultsKey)
    }

    internal func checkForDeliveredPushMessages() {
        guard let appGroup = appGroup else {
            Exponea.logger.log(.verbose, message: "No app group was setup, push delivered tracking is disabled.")
            return
        }
        guard let userDefaults = UserDefaults(suiteName: appGroup) else {
            Exponea.logger.log(.verbose, message: "Unable to load local storage of delivered push to track")
            return
        }
        trackDeliveredPushMessages(userDefaults)
        trackDeliveredPushEvents(userDefaults)
    }

    /// Loads received and stored Push notifications that were not tracked due to missing SDK configuration
    internal func trackDeliveredPushMessages(_ source: UserDefaults) {
        guard let array = source.array(forKey: Constants.General.deliveredPushUserDefaultsKey) else {
            Exponea.logger.log(.verbose, message: "No delivered push to track present in shared app group.")
            return
        }
        guard let dataArray = array as? [Data] else {
            Exponea.logger.log(.warning, message: "Delivered push data present in shared group but incorrect type.")
            return
        }
        // Process notifications
        for data in dataArray {
            guard let notification = NotificationData.deserialize(from: data) else {
                Exponea.logger.log(.warning, message: "Cannot deserialize stored delivered push data.")
                continue
            }
            trackingConsentManager.trackDeliveredPush(data: notification, mode: .CONSIDER_CONSENT)
        }
        // Clear after all is processed
        source.removeObject(forKey: Constants.General.deliveredPushUserDefaultsKey)
    }

    /// Uploads track events for delivered Push notifications that were not uploaded to backend because of some problem
    internal func trackDeliveredPushEvents(_ source: UserDefaults) {
        guard let array = source.array(forKey: Constants.General.deliveredPushEventUserDefaultsKey) else {
            Exponea.logger.log(.verbose, message: "No delivered push events to track in shared app group.")
            return
        }
        guard let dataArray = array as? [Data] else {
            Exponea.logger.log(.warning, message: "Delivered push events present in shared group but incorrect type.")
            return
        }
        // Process notification events
        for each in dataArray {
            guard let notificationEvent = EventTrackingObject.deserialize(from: each) else {
                Exponea.logger.log(.warning, message: "Cannot deserialize stored delivered push event")
                continue
            }
            trackingManager.trackDeliveredPushEvent(notificationEvent)
        }
        // Clear after all is processed
        source.removeObject(forKey: Constants.General.deliveredPushEventUserDefaultsKey)
    }

    func verifyPushStatusAndTrackPushToken() {
        UNAuthorizationStatusProvider.current.isAuthorized { authorized in
            self.stateQueue.sync {
                if self.requirePushAuthorization && !authorized {
                    if self.currentPushToken?.isTokenValid == true {
                        self.currentPushToken?.isTokenValid = false
                        self.trackCurrentPushToken(isAuthorized: authorized)
                    }
                } else {
                    let wasValid = self.currentPushToken?.isTokenValid
                    self.currentPushToken?.isTokenValid = authorized
                    if wasValid == false && authorized {
                        // Permission was re-granted after being revoked; force track regardless of frequency
                        // (token string is unchanged so frequency checks would silently skip this)
                        self.trackCurrentPushToken(isAuthorized: authorized)
                    } else {
                        self.checkForPushTokenFrequency(isAuthorized: authorized)
                    }
                }
            }
        }
    }

    private func trackCurrentPushToken(
        isAuthorized: Bool,
        isCancelled: Bool = false,
        onSuccess: (() -> Void)? = nil
    ) {
        guard !IntegrationManager.shared.isStopped else {
            Exponea.logger.log(.error, message: "trackCurrentPushToken failed, Exponea is stopped")
            return
        }
        do {
            let pushToken = currentPushToken?.pushToken
            
            try trackingManager.trackNotificationState(
                pushToken: pushToken,
                isValid: isCancelled ? false : (currentPushToken?.isTokenValid ?? true),
                description: isCancelled ?
                "Invalidated" : (
                    isAuthorized
                    ? "Permission granted"
                    : "Permission denied"
                )
            )
            // Only mark when we actually sent: trackNotificationState sends only when pushToken is non-nil.
            if pushToken != nil {
                // Commit the OS permission flag that accompanied this successful emission so
                // the next launch's `.onTokenChange` gate can detect a permission flip even
                // when the APNs token string itself has not rotated. Persisting only on
                // success (not on caller intent) keeps the cache in lockstep with what the
                // backend last received — a failed network track leaves the flag untouched,
                // so the next launch will still observe a delta and retry.
                lastPermissionFlag = isAuthorized
                userDefaults?.set(isAuthorized, forKey: Constants.General.notificationStateLastPermissionFlag)
                if !isCancelled {
                    hasTrackedThisSession = true
                }
                onSuccess?()
            }
        } catch {
            Exponea.logger.log(.error, message: "Error tracking current push token. \(error.localizedDescription)")
        }
    }

    private func markNotificationStateTracked() {
        guard isFirstNotificationStateTracking else { return }
        isFirstNotificationStateTracking = false
        userDefaults?.set(true, forKey: Constants.General.notificationStateTracked)
        
        // Only write version/applicationID when present; do not overwrite with nil.
        if let version = appVersion {
            userDefaults?.set(version, forKey: Constants.General.notificationStateAppVersion)
            Exponea.logger.log(.verbose, message: "The notification state tracked - the app version has changed")
        }
        if let applicationID = currentApplicationID {
            userDefaults?.set(applicationID, forKey: Constants.General.notificationStateApplicationID)
            Exponea.logger.log(.verbose, message: "The notification state tracked - the application ID has changed")
        }
    }

    /// Commits the tracking baseline after a successful token-registration track:
    /// advances `lastTokenTrackDate` and marks the first-track flag. Without this the next
    /// `applicationDidBecomeActive` re-check would observe `isFirstNotificationStateTracking == true`,
    /// force `effectiveLastToken = nil`, and re-emit a duplicate `notification_state` for the
    /// token just registered. Mirrors the baseline already committed by the frequency path.
    private func commitNotificationStateBaseline() {
        lastTokenTrackDate = Date()
        markNotificationStateTracked()
    }

    private func checkForPushTokenFrequency(isAuthorized authorized: Bool) {
        // Priority 1 — permission flip always emits, regardless of `tokenTrackFrequency`.
        // A permission change is a fundamental change in push reachability, so the backend
        // must observe it irrespective of the configured emission rhythm. Without this
        // hoist, `.daily` would silence a same-day permission revocation (the calendar-day
        // gate has not rolled), and `.onTokenChange` would only catch it via the
        // token-equality branch below.
        //
        // Gated on `lastPermissionFlag != nil` so the very first launch — where
        // `isFirstNotificationStateTracking` is already responsible for the initial emit
        // — does not fabricate a delta against `bool(forKey:)`'s missing-key collapse
        // to `false`. The persisted flag is compared rather than the current
        // `currentPushToken?.isTokenValid` so the signal stays anchored to "what the
        // backend last received".
        let permissionChanged = lastPermissionFlag != nil && lastPermissionFlag != authorized
        if permissionChanged {
            Exponea.logger.log(
                .verbose,
                message: "notification_state track reason: permission state changed to \(authorized)"
            )
            lastTokenTrackDate = .init()
            trackCurrentPushToken(isAuthorized: authorized, onSuccess: { [weak self] in
                self?.markNotificationStateTracked()
            })
            return
        }

        // Priority 2 — per-mode frequency rhythm. Each mode keeps its own staleness or
        // token-equality fallback so a long-running install never silently drops out of
        // the backend's 90-day validity window.
        switch tokenTrackFrequency {
        case .everyLaunch:
            guard !hasTrackedThisSession else { return }
            lastTokenTrackDate = .init()
            trackCurrentPushToken(isAuthorized: authorized, onSuccess: { [weak self] in
                self?.markNotificationStateTracked()
            })

        case .daily:
            // Calendar-day semantics for the primary gate: the previous
            // `abs(timeIntervalSince) >= 86400` measured a rolling 24h window, which
            // under-fires whenever the user opens the app on a new calendar day less than
            // 24h after the previous track (e.g. tracked at 23:55, re-opened at 00:05 the
            // next day → only 10 minutes elapsed → no track even though it is a new day).
            // `Calendar.current.isDate(_:inSameDayAs:)` makes the heartbeat fire once per
            // local calendar day, honouring the user's timezone and calendar locale.
            //
            // Staleness force-track is the secondary safety net. It is
            // functionally redundant for `.daily` under today's calendar-day gate (the
            // daily gate fires far earlier than the 30-day staleness window) but is kept
            // here as a regression guard so a future weakening of the daily gate (e.g.
            // switching to a configurable threshold) is still backed by the force-track.
            //
            // Note on `lastTokenTrackDate`: the assignment is intentionally inside the
            // `onSuccess` closure only, so a failed track does not advance the daily /
            // staleness clock and the next launch will retry — otherwise a transient
            // network failure during the staleness force-track would silence the user
            // for another full window, which is the exact bug this gate prevents.
            let now = Date()
            let isNewDay = !Calendar.current.isDate(lastTokenTrackDate, inSameDayAs: now)
            let isStale = isNotificationStateStale(at: now)
            if isNewDay || isStale {
                // Log the firing reason for consistent diagnostic output across modes.
                // The calendar-day gate wins because the staleness check is the redundant
                // fallback here.
                let trackReason: String
                if isNewDay {
                    trackReason = "new calendar day"
                } else {
                    trackReason = "\(Constants.Notifications.maxNotificationStateStalenessDays) days refresh threshold reached"
                }
                Exponea.logger.log(
                    .verbose,
                    message: "notification_state .daily track reason: \(trackReason)"
                )
                trackCurrentPushToken(isAuthorized: authorized, onSuccess: { [weak self] in
                    self?.lastTokenTrackDate = Date()
                    self?.markNotificationStateTracked()
                })
            }

        case .onTokenChange:
            // On first launch in new system treat stored CoreData token as nil to force tracking.
            // Permission-flip detection lives in the priority-1 short-circuit above;
            // this branch handles token-equality plus the staleness fallback for
            // long-lived installs.
            let effectiveLastToken = isFirstNotificationStateTracking
                ? nil
                : trackingManager.customerPushToken
            // Even when the APNs token has not changed, force-track once the persisted
            // lastTokenTrackDate is older than `maxNotificationStateStalenessDays` so long-lived
            // installs do not fall out of the backend's 90-day validity window.
            //
            // Note on `lastTokenTrackDate`: the assignment is intentionally inside the
            // `onSuccess` closure only, so a failed track does not advance the staleness clock —
            // otherwise a transient network failure during the staleness force-track would
            // silence the user for another full window, which is the exact bug this gate prevents.
            let now = Date()
            let tokenChanged = effectiveLastToken != currentPushToken?.pushToken
            let isStale = isNotificationStateStale(at: now)
            if tokenChanged || isStale {
                // Log the firing reason for consistent diagnostic output across modes.
                // Token change takes precedence over staleness because the staleness
                // check is the redundant fallback.
                let trackReason: String
                if tokenChanged {
                    trackReason = "token changed"
                } else {
                    trackReason = "\(Constants.Notifications.maxNotificationStateStalenessDays) days refresh threshold reached"
                }
                Exponea.logger.log(
                    .verbose,
                    message: "notification_state .onTokenChange track reason: \(trackReason)"
                )
                trackCurrentPushToken(isAuthorized: authorized, onSuccess: { [weak self] in
                    self?.lastTokenTrackDate = Date()
                    self?.markNotificationStateTracked()
                })
            }
        }
    }

    /// Returns `true` when the time since the last successful `notification_state` track
    /// equals or exceeds `Constants.Notifications.maxNotificationStateStalenessDays`. Uses
    /// `abs(...)` mirroring the existing `.daily` gate so a future-dated `lastTokenTrackDate`
    /// (clock rollback / restored backup) is also treated as stale and re-tracked.
    private func isNotificationStateStale(at now: Date) -> Bool {
        let stalenessSeconds = TimeInterval(
            Constants.Notifications.maxNotificationStateStalenessDays * 24 * 60 * 60
        )
        return abs(lastTokenTrackDate.timeIntervalSince(now)) >= stalenessSeconds
    }
}

extension PushNotificationManager {
    func markEveryLaunchSessionTracked() {
        stateQueue.sync {
            hasTrackedThisSession = true
        }
    }

    func applicationDidBecomeActiveUnsafe() {
        // Refresh the delivery authorization snapshot on every foreground
        // so the synchronous `state` resolution in
        // TrackingConsentManager.trackDeliveredPush reflects the user's
        // current settings (they may have toggled permissions from the
        // system Settings app while the SDK was backgrounded).
        //
        // The consume must run inside the refresh completion: refresh is
        // async and the consume reads `lastSnapshot` synchronously, so
        // without chaining the first delivered event after a permission
        // flip mid-foreground would still be resolved against the stale
        // pre-flip snapshot. verifyPushStatusAndTrackPushToken does not
        // depend on `lastSnapshot` and stays outside the completion to
        // keep its own async authorization path independent of the
        // delivery-authorization refresh.
        DeliveryAuthorizationProvider.refresh { [weak self] in
            self?.checkForDeliveredPushMessages()
        }
        // we don't have to check for opened pushes here, Exponea SDK was initialized so it will be tracked directly
        verifyPushStatusAndTrackPushToken()
    }
}
