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
open class TrackingManager {
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
    
    internal let reachability: Reachability
    
    /// The manager for automatic push registration and delivery tracking
    internal var notificationsManager: PushNotificationManagerType?
    
    /// Used for periodic data flushing.
    internal var flushingTimer: Timer?
    
    /// User defaults used to store basic data and flags.
    internal let userDefaults: UserDefaults
    
    internal var isFlushingData: Bool = false
    
    // Background task, if there is any - used to track sessions and flush data.
    internal var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid {
        didSet {
            if backgroundTask == UIBackgroundTaskInvalid && backgroundWorkItem != nil {
                Exponea.logger.log(.verbose, message: "Background task ended, stopping background work item.")
                backgroundWorkItem?.cancel()
                backgroundWorkItem = nil
            }
        }
    }

    internal var backgroundWorkItem: DispatchWorkItem? {
        didSet {
            // Stop background taks if work item is done
            if backgroundWorkItem == nil && backgroundTask != UIBackgroundTaskInvalid {
                Exponea.logger.log(.verbose, message: "Stopping background task after work item done/cancelled.")
                UIApplication.shared.endBackgroundTask(backgroundTask)
                backgroundTask = UIBackgroundTaskInvalid
            }
        }
    }
    
    /// Flushing mode specifies how often and if should data be automatically flushed to Exponea.
    /// See `FlushingMode` for available values.
    public var flushingMode: FlushingMode = .immediate {
        didSet {
            Exponea.logger.log(.verbose, message: "Flushing mode updated to: \(flushingMode).")
            updateFlushingMode()
        }
    }
    
    init(repository: RepositoryType,
         database: DatabaseManagerType,
         device: DeviceProperties = DeviceProperties(),
         paymentManager: PaymentManagerType = PaymentManager(),
         userDefaults: UserDefaults) {
        self.repository = repository
        self.database = database
        self.device = device
        self.paymentManager = paymentManager
        self.userDefaults = userDefaults
        
        // Start reachability
        self.reachability = Reachability(hostname: repository.configuration.hostname)!
        try? self.reachability.startNotifier()
        
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
            notificationsManager = PushNotificationManager(trackingManager: self)
        }
        
        // First remove all observing
        NotificationCenter.default.removeObserver(self)
        
        // Always track when we become active, enter background or terminate (used for both sessions and data flushing)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive),
                                               name: .UIApplicationDidBecomeActive,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackground),
                                               name: .UIApplicationDidEnterBackground,
                                               object: nil)
    }
    
    /// Installation event is fired only once for the whole lifetime of the app on one
    /// device when the app is launched for the first time.
    internal func trackInstallEvent() {
        /// Checking if the APP was launched before.
        /// If the key value is false, means that the event was not fired before.
        let key = Constants.Keys.installTracked + (database.customer.uuid?.uuidString ?? "")
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
    
    open func track(_ type: EventType, with data: [DataType]?) throws {
        /// Get token mapping or fail if no token provided.
        let tokens = repository.configuration.tokens(for: type)
        if tokens.isEmpty {
            throw TrackingManagerError.unknownError("No project tokens provided.")
        }
        
        Exponea.logger.log(.verbose, message: "Tracking event of type: \(type).")
        
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
            }
        }
        
        // If we have immediate flushing mode, flush after tracking
        if case .immediate = flushingMode {
            flushData()
        }
    }

    open func identifyCustomer(with data: [DataType]) throws {
        try database.identifyCustomer(with: data)
    }
    
    open func trackInstall(with data: [DataType]) throws {
        try database.trackEvent(with: data + [.eventType(Constants.EventTypes.installation)])
    }
    
    open func trackEvent(with data: [DataType]) throws {
        try database.trackEvent(with: data)
    }
    
    open func trackPayment(with data: [DataType]) throws {
        try database.trackEvent(with: data + [.eventType(Constants.EventTypes.payment)])
    }
    
    open func trackPushToken(with data: [DataType]) throws {
        try database.identifyCustomer(with: data)
    }
    
    open func trackPushOpened(with data: [DataType]) throws {
        try database.trackEvent(with: data + [.eventType(Constants.EventTypes.pushOpen)])
    }
    
    open func trackPushDelivered(with data: [DataType]) throws {
        try database.trackEvent(with: data + [.eventType(Constants.EventTypes.pushDelivered)])
    }
    
    open func trackStartSession(with data: [DataType]) throws {
        try database.trackEvent(with: data + [.eventType(Constants.EventTypes.sessionStart)])
    }
    
    open func trackEndSession(with data: [DataType]) throws {
        try database.trackEvent(with: data + [.eventType(Constants.EventTypes.sessionEnd)])
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
        sessionStartTime = Date().timeIntervalSince1970
        
        // Track session start
        try track(.sessionStart, with: [.properties(device.properties),
                                        .timestamp(sessionStartTime)])
        
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
        // Cancel background task if we have any
        if let item = backgroundWorkItem {
            item.cancel()
            backgroundWorkItem = nil
        }
        
        // Reschedule flushing timer if using periodic flushing mode
        if case let .periodic(interval) = flushingMode {
            flushingTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(interval),
                                                 repeats: true) { _ in
                self.flushData()
            }
        }
        
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
        // Save last session background time, in case we get terminated
        sessionBackgroundTime = Date().timeIntervalSince1970
        
        // Make sure to not create a new background task, if we already have one.
        guard backgroundTask == UIBackgroundTaskInvalid else {
            return
        }
        
        // Start the background task
        backgroundTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            UIApplication.shared.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = UIBackgroundTaskInvalid
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
        return DispatchWorkItem { [weak self] in
            guard let `self` = self else { return }
            
            // If we're cancelled, stop background task
            if self.backgroundWorkItem?.isCancelled ?? false {
                UIApplication.shared.endBackgroundTask(self.backgroundTask)
                self.backgroundTask = UIBackgroundTaskInvalid
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
            
            switch self.flushingMode {
            case .periodic(_):
                // Invalidate the timer
                self.flushingTimer?.invalidate()
                self.flushingTimer = nil
                
                // Continue to flush data on line below
                fallthrough
                
            case .automatic, .immediate:
                // Only stop background task after we upload
                self.flushData(completion: { [weak self] in
                    guard let weakSelf = self else { return }
                    UIApplication.shared.endBackgroundTask(weakSelf.backgroundTask)
                    weakSelf.backgroundTask = UIBackgroundTaskInvalid
                })
                
            default:
                // We're done
                UIApplication.shared.endBackgroundTask(self.backgroundTask)
                self.backgroundTask = UIBackgroundTaskInvalid
            }
        }
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

// MARK: - Flushing -

extension TrackingManager {
    
    @objc func flushData() {
        flushData(completion: nil)
    }
    
    /// Method that flushes all data to the API.
    ///
    /// - Parameter completion: A completion that is called after all calls succeed or fail.
    func flushData(completion: (() -> Void)?) {
        do {
            // Check if flush is in progress
            guard !isFlushingData else {
                Exponea.logger.log(.warning, message: "Data flushing in progress, ignoring another flush call.")
                completion?()
                return
            }
            
            // Check if we have an internet connection otherwise bail
            guard reachability.connection != .none else {
                Exponea.logger.log(.warning, message: "Connection issues when flushing data, not flushing.")
                completion?()
                return
            }
            
            // Pull from db
            let events = try database.fetchTrackEvent().reversed()
            let customers = try database.fetchTrackCustomer().reversed()
            
            Exponea.logger.log(.verbose, message: """
                Flushing data: \(events.count + customers.count) total objects to upload, \
                \(events.count) events and \(customers.count) customer updates.
                """)
            
            // Check if we have any data otherwise bail
            guard !events.isEmpty || !customers.isEmpty else {
                return
            }
            
            var customersDone = false
            var eventsDone = false
            
            isFlushingData = true
            
            flushCustomerTracking(Array(customers), completion: {
                customersDone = true
                if eventsDone && customersDone {
                    self.isFlushingData = false
                    completion?()
                }
            })
            flushEventTracking(Array(events), completion: {
                eventsDone = true
                if eventsDone && customersDone {
                    self.isFlushingData = false
                    completion?()
                }
            })
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
        }
    }
    
    func flushCustomerTracking(_ customers: [TrackCustomer], completion: (() -> Void)? = nil) {
        var counter = customers.count
        for customer in customers {
            repository.trackCustomer(with: customer.dataTypes, for: customerIds) { [weak self] (result) in
                switch result {
                case .success:
                    Exponea.logger.log(.verbose, message: """
                        Successfully uploaded customer update: \(customer.objectID).
                        """)
                    do {
                        try self?.database.delete(customer)
                    } catch {
                        Exponea.logger.log(.error, message: """
                            Failed to remove object from database: \(customer.objectID).
                            \(error.localizedDescription)
                            """)
                    }
                case .failure(let error):
                    switch error {
                    case .connectionError, .serverError(nil):
                        // If server or connection error, bail here and do not increase retry count
                        Exponea.logger.log(.warning, message: """
                            Failed to upload customer event due to connection or server error. \
                            \(error.localizedDescription)
                            """)
                        break
                        
                    default:
                        // Handle all other errors regularly
                        Exponea.logger.log(.error, message: """
                            Failed to upload customer update. \(error.localizedDescription)
                            """)
                        
                        // Increase the retry count
                        let retries = NSNumber(integerLiteral: customer.retries.intValue + 1)
                        customer.retries = retries
                        
                        // If we have reached the max count of retries, delete the object.
                        // Otherwise save changes and try again next time.
                        do {
                            let max = self?.repository.configuration.flushEventMaxRetries ?? Constants.Session.maxRetries
                            if customer.retries.intValue >= max {
                                Exponea.logger.log(.error, message: """
                                    Maximum retry count reached, deleting customer event: \(customer.objectID)
                                    """)
                                try self?.database.delete(customer)
                            } else {
                                Exponea.logger.log(.error, message: """
                                    Increasing retry count (\(customer.retries)) for customer event: \(customer.objectID)
                                    """)
                                try self?.database.save()
                            }
                        } catch {
                            Exponea.logger.log(.error, message: """
                                Failed to update retry count or remove object from database: \(customer.objectID).
                                \(error.localizedDescription)
                                """)
                        }
                    }
                }
                
                // Handle request counter, potentially call completion
                counter -= 1
                if counter == 0 {
                    completion?()
                }
            }
        }
        
        // If we have no customer updates, call completion
        if customers.isEmpty {
            completion?()
        }
    }
    
    func flushEventTracking(_ events: [TrackEvent], completion: (() -> Void)? = nil) {
        var counter = events.count
        for event in events {
            repository.trackEvent(with: event.dataTypes, for: customerIds) { [weak self] (result) in
                switch result {
                case .success:
                    Exponea.logger.log(.verbose, message: "Successfully uploaded event: \(event.objectID).")
                    do {
                        try self?.database.delete(event)
                    } catch {
                        Exponea.logger.log(.error, message: """
                            Failed to remove object from database: \(event.objectID). \(error.localizedDescription)
                            """)
                    }
                case .failure(let error):
                    switch error {
                    case .connectionError, .serverError(_):
                        // If server or connection error, bail here and do not increase retry count
                        Exponea.logger.log(.warning, message: """
                            Failed to upload event due to connection or server error. \
                            \(error.localizedDescription)
                            """)
                        break
                        
                    default:
                        Exponea.logger.log(.error, message: "Failed to upload event. \(error.localizedDescription)")
                        
                        // Increase the retry count
                        let retries = NSNumber(integerLiteral: event.retries.intValue + 1)
                        event.retries = retries
                        
                        // If we have reached the max count of retries, delete the object.
                        // Otherwise save changes and try again next time.
                        do {
                            let max = self?.repository.configuration.flushEventMaxRetries ?? Constants.Session.maxRetries
                            if event.retries.intValue >= max {
                                Exponea.logger.log(.error, message: """
                                    Maximum retry count reached, deleting event: \(event.objectID)
                                    """)
                                try self?.database.delete(event)
                            } else {
                                Exponea.logger.log(.error, message: """
                                    Increasing retry count (\(event.retries)) for event: \(event.objectID)
                                    """)
                                try self?.database.save()
                            }
                        } catch {
                            Exponea.logger.log(.error, message: """
                                Failed to update retry count or remove object from database: \(event.objectID).
                                \(error.localizedDescription)
                                """)
                        }
                    }
                }
                
                // Handle request counter, potentially call completion
                counter -= 1
                if counter == 0 {
                    completion?()
                }
            }
        }
        
        // If we have no events, call completion
        if events.isEmpty {
            completion?()
        }
    }
    
    func updateFlushingMode() {
        // Invalidate timers
        flushingTimer?.invalidate()
        flushingTimer = nil
        
        // Update for new flushing mode
        switch flushingMode {
        case .immediate:
            // Immediately flush any data we might have
            flushData()
            
        case .periodic(let interval):
            // Schedule a timer for the specified interval
            flushingTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(interval),
                                                 repeats: true) { _ in
                self.flushData()
            }
        default:
            // No need to do anything for manual or automatic (tracked on app events) or immediate
            break
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
            
            // Re-do initial setup
            initialSetup()
        }
        
        let currentToken = customerPushToken
        if let token = currentToken, let projectToken = repository.configuration.tokens(for: .registerPushToken).first {
            try trackPushToken(with: [.projectToken(projectToken), .pushNotificationToken(nil)])
            flushData {
                do {
                    try perform()
                    try self.trackPushToken(with: [.projectToken(projectToken), .pushNotificationToken(token)])
                } catch {
                    Exponea.logger.log(.error, message: error.localizedDescription)
                }
                self.flushData()
            }
        } else {
            try perform()
        }
    }
}
