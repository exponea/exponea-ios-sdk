//
//  TrackingManager.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 11/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// The Tracking Manager class is responsible to manage the automatic tracking events when
/// it's enable and persist the data according to each event type.
class TrackingManager {
    let database: DatabaseManagerType
    let repository: RepositoryType
    let device: DeviceProperties

    /// The identifiers of the the current customer.
    var customerIds: [String: JSONValue] {
        return database.customer.ids
    }

    /// Returns the push token of the current customer if there is any.
    var customerPushToken: String? {
        return database.customer.pushToken
    }

    /// Payment manager responsible to track all in app payments.
    internal var paymentManager: PaymentManagerType {
        didSet {
            paymentManager.delegate = self
            paymentManager.startObservingPayments()
        }
    }

    /// The manager for automatic push registration and delivery tracking
    internal var notificationsManager: PushNotificationManagerType?

    /// Manager responsible for loading and displaying in-app messages
    internal var inAppMessagesManager: InAppMessagesManagerType

    internal var flushingManager: FlushingManagerType

    /// User defaults used to store basic data and flags.
    internal let userDefaults: UserDefaults

    // Background task, if there is any - used to track sessions and flush data.
    internal var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid {
        didSet {
            if backgroundTask == UIBackgroundTaskIdentifier.invalid && backgroundWorkItem != nil {
                Exponea.logger.log(.verbose, message: "Background task ended, stopping background work item.")
                backgroundWorkItem?.cancel()
                backgroundWorkItem = nil
            }
        }
    }

    internal var backgroundWorkItem: DispatchWorkItem? {
        didSet {
            // Stop background taks if work item is done
            if backgroundWorkItem == nil && backgroundTask != UIBackgroundTaskIdentifier.invalid {
                Exponea.logger.log(.verbose, message: "Stopping background task after work item done/cancelled.")
                UIApplication.shared.endBackgroundTask(backgroundTask)
                backgroundTask = UIBackgroundTaskIdentifier.invalid
            }
        }
    }

    init(repository: RepositoryType,
         database: DatabaseManagerType,
         device: DeviceProperties = DeviceProperties(),
         flushingManager: FlushingManagerType,
         paymentManager: PaymentManagerType = PaymentManager(),
         userDefaults: UserDefaults) throws {
        self.repository = repository
        self.database = database
        self.device = device
        self.paymentManager = paymentManager
        self.userDefaults = userDefaults

        self.flushingManager = flushingManager

        self.inAppMessagesManager = InAppMessagesManager(
            repository: repository,
            displayStatusStore: InAppMessageDisplayStatusStore(userDefaults: userDefaults)
        )

        initialSetup()
    }

    deinit {
        Exponea.logger.log(.verbose, message: "TrackingManager deallocated.")
    }

    func initialSetup() {
        // Track initial install event if necessary.
        trackInstallEvent()

        /// Add the observers when the automatic session tracking is true.
        if repository.configuration.automaticSessionTracking {
            do {
                try triggerInitialSession()
            } catch {
                Exponea.logger.log(.error, message: "Session start tracking error: \(error.localizedDescription)")
            }
        }

        /// Add the observers when the automatic push notification tracking is true.
        if repository.configuration.automaticPushNotificationTracking {
            notificationsManager = PushNotificationManager(
                trackingManager: self,
                appGroup: repository.configuration.appGroup,
                tokenTrackFrequency: repository.configuration.tokenTrackFrequency,
                currentPushToken: database.customer.pushToken,
                lastTokenTrackDate: database.customer.lastTokenTrackDate
            )
        }

        // First remove all observing
        NotificationCenter.default.removeObserver(self)

        // Always track when we become active, enter background or terminate (used for both sessions and data flushing)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)

        inAppMessagesManager.preload(for: customerIds)
    }

    /// Installation event is fired only once for the whole lifetime of the app on one
    /// device when the app is launched for the first time.
    internal func trackInstallEvent() {
        /// Checking if the APP was launched before.
        /// If the key value is false, means that the event was not fired before.
        let key = Constants.Keys.installTracked + database.customer.uuid.uuidString
        guard userDefaults.bool(forKey: key) == false else {
            Exponea.logger.log(.verbose, message: "Install event was already tracked, skipping.")
            return
        }

        /// In case the event was not fired, we call the track manager
        /// passing the install event type.
        do {
            // Get depdencies and track install event
            try track(.install, with: [.properties(device.properties),
                                       .timestamp(Date().timeIntervalSince1970)])

            /// Set the value to true if event was executed successfully
            userDefaults.set(true, forKey: key)
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
        }
    }
}

// MARK: -

extension TrackingManager: TrackingManagerType {
    public func hasPendingEvent(ofType type: String, withMaxAge maxAge: Double) throws -> Bool {
        let events = try database.fetchTrackEvent()
            .filter({ $0.eventType == type && $0.timestamp + maxAge >= Date().timeIntervalSince1970})
        return !events.isEmpty
    }

    // Updates last logged event of given type with data
    // Event may be logged multiple times - for every project token
    public func updateLastPendingEvent(ofType type: String, with data: DataType) throws {
        var events = try database.fetchTrackEvent()
            .filter({ $0.eventType == type })
            .sorted(by: {$0.timestamp < $1.timestamp})
        var projectTokens: Set<String> = []
        while !events.isEmpty {
            let event = events.removeLast()
            if let projectToken = event.projectToken, !projectTokens.contains(projectToken) {
                projectTokens.insert(projectToken)
                try database.updateEvent(withId: event.managedObjectID, withData: data)
            }
        }
    }

    open func track(_ type: EventType, with data: [DataType]?) throws {
        /// Get token mapping or fail if no token provided.
        let tokens = repository.configuration.tokens(for: type)
        if tokens.isEmpty {
            throw TrackingManagerError.unknownError("No project tokens provided.")
        }

        Exponea.logger.log(.verbose, message: "Tracking event of type: \(type) with params \(data ?? [])")

        /// For each project token we have, track the data.
        for projectToken in tokens {
            let payload: [DataType] = [.projectToken(projectToken)] + (data ?? [])

            switch type {
            case .install: try trackInstall(with: payload)
            case .sessionStart: try trackStartSession(with: payload)
            case .sessionEnd: try trackEndSession(with: payload)
            case .customEvent: try trackEvent(with: payload)
            case .identifyCustomer: try identifyCustomer(with: payload)
            case .payment: try trackPayment(with: payload)
            case .registerPushToken: try trackPushToken(with: payload)
            case .pushOpened: try trackPushOpened(with: payload)
            case .pushDelivered: try trackPushDelivered(with: payload)
            case .campaignClick: try trackCampaignClick(with: payload)
            case .banner: try trackBanner(with: payload)
            }
        }

        // If we have immediate flushing mode, flush after tracking
        if case .immediate = self.flushingManager.flushingMode {
            self.flushingManager.flushDataWith(delay: Constants.Tracking.immediateFlushDelay)
        }
    }

    open func identifyCustomer(with data: [DataType]) throws {
        try database.identifyCustomer(with: data)
    }

    open func trackInstall(with data: [DataType]) throws {
        try database.trackEvent(with: data + [.eventType(Constants.EventTypes.installation)])
        self.inAppMessagesManager.showInAppMessage(
            for: Constants.EventTypes.installation,
            trackingDelegate: self
        )
    }

    open func trackEvent(with data: [DataType]) throws {
        try database.trackEvent(with: data)
        let eventTypes = data.compactMap { dataType -> String? in
            if case DataType.eventType(let eventType) = dataType {
                return eventType
            }
            return nil
        }
        eventTypes.forEach {
           self.inAppMessagesManager.showInAppMessage(for: $0, trackingDelegate: self)
        }
    }

    open func trackCampaignClick(with data: [DataType]) throws {
        try database.trackEvent(with: data + [.eventType(Constants.EventTypes.campaignClick)])
        self.inAppMessagesManager.showInAppMessage(
            for: Constants.EventTypes.campaignClick,
            trackingDelegate: self
        )
    }

    open func trackPayment(with data: [DataType]) throws {
        try database.trackEvent(with: data + [.eventType(Constants.EventTypes.payment)])
        self.inAppMessagesManager.showInAppMessage(
            for: Constants.EventTypes.payment,
            trackingDelegate: self
        )
    }

    open func trackPushToken(with data: [DataType]) throws {
        try database.identifyCustomer(with: data)
    }

    open func trackPushOpened(with data: [DataType]) throws {
        try database.trackEvent(with: data + [.eventType(Constants.EventTypes.pushOpen)])
        self.inAppMessagesManager.showInAppMessage(
            for: Constants.EventTypes.pushOpen,
            trackingDelegate: self
        )
    }

    open func trackPushDelivered(with data: [DataType]) throws {
        try database.trackEvent(with: data + [.eventType(Constants.EventTypes.pushDelivered)])
        self.inAppMessagesManager.showInAppMessage(
            for: Constants.EventTypes.pushDelivered,
            trackingDelegate: self
        )
    }

    open func trackStartSession(with data: [DataType]) throws {
        try database.trackEvent(with: data + [.eventType(Constants.EventTypes.sessionStart)])
        self.inAppMessagesManager.showInAppMessage(
            for: Constants.EventTypes.sessionStart,
            trackingDelegate: self
        )
    }

    open func trackEndSession(with data: [DataType]) throws {
        try database.trackEvent(with: data + [.eventType(Constants.EventTypes.sessionEnd)])
        self.inAppMessagesManager.showInAppMessage(
            for: Constants.EventTypes.sessionEnd,
            trackingDelegate: self
        )
    }

    open func trackBanner(with data: [DataType]) throws {
        try database.trackEvent(with: data + [.eventType(Constants.EventTypes.banner)])
    }
}

// MARK: - Sessions

extension TrackingManager {
    internal var sessionStartTime: Double {
        get {
            return userDefaults.double(forKey: Constants.Keys.sessionStarted)
        }
        set {
            userDefaults.set(newValue, forKey: Constants.Keys.sessionStarted)
        }
    }

    internal var sessionEndTime: Double {
        get {
            return userDefaults.double(forKey: Constants.Keys.sessionEnded)
        }
        set {
            userDefaults.set(newValue, forKey: Constants.Keys.sessionEnded)
        }
    }

    internal var sessionBackgroundTime: Double {
        get {
            return userDefaults.double(forKey: Constants.Keys.sessionBackgrounded)
        }
        set {
            userDefaults.set(newValue, forKey: Constants.Keys.sessionBackgrounded)
        }
    }

    var hasActiveSession: Bool {
        return sessionStartTime != 0
    }

    internal func triggerInitialSession() throws {
        // If we have a previously started session and a last session background time,
        // but no end time then we can assume that the app was terminated and we can use
        // the last background time as a session end.
        if sessionStartTime != 0 && sessionEndTime == 0 && sessionBackgroundTime != 0 {
            sessionEndTime = sessionBackgroundTime
            sessionBackgroundTime = 0
        }

        try triggerSessionStart()
    }

    open func triggerSessionStart() throws {
        // If session end time is set, app was terminated
        if sessionStartTime != 0 && sessionEndTime != 0 {
            Exponea.logger.log(.verbose, message: "App was terminated previously, first tracking previous session end.")
            try triggerSessionEnd()
        }

        // Track previous session if we are past session timeout
        if shouldTrackCurrentSession {
            Exponea.logger.log(.verbose, message: "We're past session timeout, first tracking previous session end.")
            try triggerSessionEnd()
        } else if sessionStartTime != 0 {
            Exponea.logger.log(.verbose, message: "Continuing current session as we're within session timeout.")
            return
        }

        // Start the session with current date
        let sessionStartDate = Date()
        sessionStartTime = sessionStartDate.timeIntervalSince1970
        inAppMessagesManager.sessionDidStart(at: sessionStartDate)

        let data: [DataType] = [
            .properties(device.properties),
            .timestamp(sessionStartTime)
        ]

        // Track session start
        try track(.sessionStart, with: data)

        Exponea.logger.log(.verbose, message: Constants.SuccessMessages.sessionStart)
    }

    open func triggerSessionEnd() throws {
        guard sessionStartTime != 0 else {
            Exponea.logger.log(.error, message: "Can't end session as no session was started.")
            return
        }

        // Set the session end to the time when session end is triggered or if it was set previously
        // (for example after app has been terminated)
        sessionEndTime = sessionEndTime == 0 ? Date().timeIntervalSince1970 : sessionEndTime

        // Prepare data to persist into coredata.
        var properties = device.properties

        // Calculate the duration of the session and add to properties.
        let duration = sessionEndTime - sessionStartTime
        properties["duration"] = .double(duration)

        // Track session end
        try track(.sessionEnd, with: [.properties(properties),
                                      .timestamp(sessionEndTime)])

        // Reset session times
        sessionStartTime = 0
        sessionEndTime = 0

        Exponea.logger.log(.verbose, message: Constants.SuccessMessages.sessionEnd)
    }

    @objc internal func applicationDidBecomeActive() {
        Exponea.shared.executeSafely {
            applicationDidBecomeActiveUnsafe()
        }
    }

    internal func applicationDidBecomeActiveUnsafe() {
        // Cancel background task if we have any
        if let item = backgroundWorkItem {
            item.cancel()
            backgroundWorkItem = nil
        }

        // Let the notification manager know the app has becom active
        notificationsManager?.applicationDidBecomeActive()

        flushingManager.applicationDidBecomeActive()

        // Track session start, if we are allowed to
        if repository.configuration.automaticSessionTracking {
            do {
                try triggerSessionStart()
            } catch {
                Exponea.logger.log(.error, message: "Session start tracking error: \(error.localizedDescription)")
            }
        }
    }

    @objc internal func applicationDidEnterBackground() {
        Exponea.shared.executeSafely {
            applicationDidEnterBackgroundUnsafe()
        }
    }

    internal func applicationDidEnterBackgroundUnsafe() {
        self.flushingManager.applicationDidEnterBackground()
        // Save last session background time, in case we get terminated
        sessionBackgroundTime = Date().timeIntervalSince1970

        // Make sure to not create a new background task, if we already have one.
        guard backgroundTask == UIBackgroundTaskIdentifier.invalid else {
            return
        }

        // Start the background task
        backgroundTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            UIApplication.shared.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = UIBackgroundTaskIdentifier.invalid
        })

        // Dispatch after default session timeout
        let queue = DispatchQueue.global(qos: .background)
        let item = createBackgroundWorkItem()
        backgroundWorkItem = item

        // Schedule the task to run using delay if applicable
        let shouldDelay = repository.configuration.automaticSessionTracking
        let delay = shouldDelay ? Constants.Session.defaultTimeout : 0
        queue.asyncAfter(deadline: .now() + delay, execute: item)

        Exponea.logger.log(.verbose, message: "Started background task with delay \(delay)s.")
    }

    internal func createBackgroundWorkItem() -> DispatchWorkItem {
        let unsafeWork = { [weak self] in
            guard let `self` = self else { return }

            // If we're cancelled, stop background task
            if self.backgroundWorkItem?.isCancelled ?? false {
                UIApplication.shared.endBackgroundTask(self.backgroundTask)
                self.backgroundTask = UIBackgroundTaskIdentifier.invalid
                return
            }

            // If we track sessions automatically
            if self.repository.configuration.automaticSessionTracking {
                do {
                    try self.triggerSessionEnd()
                    self.sessionBackgroundTime = 0
                } catch {
                    Exponea.logger.log(.error, message: "Session end tracking error: \(error.localizedDescription)")
                }
            }

            switch self.flushingManager.flushingMode {
            case .periodic, .automatic, .immediate:
                // Only stop background task after we upload
                self.flushingManager.flushData(completion: { [weak self] in
                    guard let weakSelf = self else { return }
                    UIApplication.shared.endBackgroundTask(weakSelf.backgroundTask)
                    weakSelf.backgroundTask = UIBackgroundTaskIdentifier.invalid
                })

            default:
                // We're done
                UIApplication.shared.endBackgroundTask(self.backgroundTask)
                self.backgroundTask = UIBackgroundTaskIdentifier.invalid
            }
        }

        return DispatchWorkItem { Exponea.shared.executeSafely { unsafeWork() } }
    }

    internal var shouldTrackCurrentSession: Bool {
        /// Avoid tracking if session not started
        guard sessionStartTime != 0 else {
            return false
        }

        // Get current time to calculate duration
        let currentTime = Date().timeIntervalSince1970

        /// Calculate the session duration
        let sessionDuration = sessionEndTime - currentTime

        /// Session should be ended
        if sessionDuration > repository.configuration.sessionTimeout {
            return true
        } else {
            return false
        }
    }
}

// MARK: - Payments -

extension TrackingManager: PaymentManagerDelegate {
    public func trackPaymentEvent(with data: [DataType]) {
        do {
            try track(.payment, with: data)
            Exponea.logger.log(.verbose, message: Constants.SuccessMessages.paymentDone)
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
        }
    }
}

// MARK: - In-app messages -

extension TrackingManager: InAppMessageTrackingDelegate {
    public func track(message: InAppMessage, action: String, interaction: Bool) {
        do {
            try track(
                .banner,
                with: [
                    .properties(device.properties),
                    .properties([
                        "action": .string(action),
                        "banner_id": .string(message.id),
                        "banner_name": .string(message.name),
                        "banner_type": .string(message.messageType),
                        "interaction": .bool(interaction),
                        "os": .string("iOS"),
                        "type": .string("in-app message"),
                        "variant_id": .int(message.variantId),
                        "variant_name": .string(message.variantName)
                    ])
                ]
            )
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
        }
    }
}

// MARK: - Anonymize -

extension TrackingManager {
    public func anonymize() throws {
        func perform() throws {
            // Cancel all request (in case flushing was ongoing)
            repository.cancelRequests()

            // Clear all database contents
            try database.clear()

            // Clear the session data
            sessionStartTime = 0
            sessionBackgroundTime = 0
            sessionEndTime = 0

            inAppMessagesManager.anonymize()

            // Re-do initial setup
            initialSetup()
        }

        let currentToken = customerPushToken
        if let token = currentToken, let projectToken = repository.configuration.tokens(for: .registerPushToken).first {
            try trackPushToken(with: [.projectToken(projectToken), .pushNotificationToken(nil)])
            self.flushingManager.flushData {
                do {
                    try perform()
                    try self.trackPushToken(with: [.projectToken(projectToken), .pushNotificationToken(token)])
                } catch {
                    Exponea.logger.log(.error, message: error.localizedDescription)
                }
                self.flushingManager.flushData()
            }
        } else {
            try perform()
        }
    }
}
