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
    
    /// Payment manager responsible to track all in app payments.
    internal var paymentManager: PaymentManagerType {
        didSet {
            paymentManager.delegate = self
            paymentManager.startObservingPayments()
        }
    }
    
    /// The manager for automatic push registration and delivery tracking
    internal var pushManager: PushNotificationManager?
    
    /// Used for periodic data flushing.
    internal var flushingTimer: Timer?
    
    /// User defaults used to store basic data and flags.
    internal let userDefaults: UserDefaults
    
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
    public var flushingMode: FlushingMode = .automatic {
        didSet {
            Exponea.logger.log(.verbose, message: "Flushing mode updated to: \(flushingMode).")
            updateFlushingMode()
        }
    }
    
    init(repository: RepositoryType,
         database: DatabaseManagerType = DatabaseManager(),
         device: DeviceProperties = DeviceProperties(),
         paymentManager: PaymentManagerType = PaymentManager(),
         userDefaults: UserDefaults) {
        self.repository = repository
        self.database = database
        self.device = device
        self.paymentManager = paymentManager
        self.userDefaults = userDefaults
        
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
            try? track(.sessionStart, with: nil)
        }
        
        /// Add the observers when the automatic push notification tracking is true.
        if repository.configuration.automaticPushNotificationTracking {
            pushManager = PushNotificationManager(trackingManager: self)
        }
        
        // Always track when we become active, enter background or terminate (used for both sessions and data flushing)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive),
                                               name: .UIApplicationDidBecomeActive,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackground),
                                               name: .UIApplicationDidEnterBackground,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillTerminate),
                                               name: .UIApplicationWillTerminate,
                                               object: nil)
    }
    
    /// Installation event is fired only once for the whole lifetime of the app on one
    /// device when the app is launched for the first time.
    internal func trackInstallEvent() {
        /// Checking if the APP was launched before.
        /// If the key value is false, means that the event was not fired before.
        guard userDefaults.bool(forKey: Constants.Keys.launchedBefore) == false else {
            Exponea.logger.log(.verbose, message: "Install event was already tracked, skipping.")
            return
        }
        
        /// In case the event was not fired, we call the track manager
        /// passing the install event type.
        do {
            // Get depdencies and track install event
            try track(.install, with: nil)
            
            /// Set the value to true if event was executed successfully
            userDefaults.set(true, forKey: Constants.Keys.launchedBefore)
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
        }
    }
}

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
            case .install: try trackInstall(projectToken: projectToken)
            case .sessionStart: try trackStartSession(projectToken: projectToken)
            case .sessionEnd: try trackEndSession(projectToken: projectToken)
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
}

extension TrackingManager {
    open func trackInstall(projectToken: String) throws {
        try database.trackEvent(with: [.projectToken(projectToken),
                                       .properties(device.properties),
                                       .eventType(Constants.EventTypes.installation)])
    }
    
    open func trackEvent(with data: [DataType]) throws {
        try database.trackEvent(with: data)
    }
    
    open func identifyCustomer(with data: [DataType]) throws {
        try database.trackCustomer(with: data)
    }
    
    open func trackPayment(with data: [DataType]) throws {
        try database.trackEvent(with: data + [.eventType(Constants.EventTypes.payment)])
    }
    
    open func trackPushToken(with data: [DataType]) throws {
        try database.trackCustomer(with: data)
    }
    
    open func trackPushOpened(with data: [DataType]) throws {
        try database.trackEvent(with: data + [.eventType(Constants.EventTypes.pushOpen)])
    }
    
    open func trackPushDelivered(with data: [DataType]) throws {
        try database.trackEvent(with: data + [.eventType(Constants.EventTypes.pushDelivered)])
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
    
    @objc internal func applicationDidBecomeActive() {
        // Cancel background task if we have any
        if let item = backgroundWorkItem {
            item.cancel()
            backgroundWorkItem = nil
            return
        }
        
        // Reschedule flushing timer if using periodic flushing mode
        if case let .periodic(interval) = flushingMode {
            flushingTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(interval),
                                                 repeats: true) { _ in
                self.flushData()
            }
        }
        
        // Make sure we are allowed to automatically track sessions
        if !repository.configuration.automaticSessionTracking {
            return
        }
        
        // If this is first session start, then
        guard sessionStartTime != 0 else {
            Exponea.logger.log(.verbose, message: "Starting first session.")
            sessionStartTime = Date().timeIntervalSince1970

            // Track session end, if we are allowed to
            if repository.configuration.automaticSessionTracking {
                try? track(.sessionStart, with: nil)
            }
            
            return
        }
        
        // Check first if we're past session timeout. If yes, track end of a session.
        if shouldTrackCurrentSession {
            do {
                // Track session end
                try track(.sessionEnd, with: nil)
                
                // Reset session
                sessionStartTime = Date().timeIntervalSince1970
                sessionEndTime = 0
                
                Exponea.logger.log(.verbose, message: Constants.SuccessMessages.sessionEnd)
            } catch {
                Exponea.logger.log(.error, message: error.localizedDescription)
            }
        } else {
            Exponea.logger.log(.verbose, message: "Skipping tracking session end as within timeout or not started.")
        }
    }
    
    @objc internal func applicationDidEnterBackground() {
        backgroundTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            UIApplication.shared.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = UIBackgroundTaskInvalid
        })
        
        // Dispatch after default session timeout
        let queue = DispatchQueue.global(qos: .background)
        let item = DispatchWorkItem {
            if self.repository.configuration.automaticSessionTracking {
                self.triggerEndSession()
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
                self.flushData(completion: {
                    UIApplication.shared.endBackgroundTask(self.backgroundTask)
                    self.backgroundTask = UIBackgroundTaskInvalid
                })
                
            default:
                // We're done
                UIApplication.shared.endBackgroundTask(self.backgroundTask)
                self.backgroundTask = UIBackgroundTaskInvalid
            }
        }
        
        backgroundWorkItem = item
        queue.asyncAfter(deadline: .now() + Constants.Session.defaultTimeout, execute: item)
    }
    
    @objc internal func applicationWillTerminate() {
        backgroundTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            UIApplication.shared.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = UIBackgroundTaskInvalid
        })
        
        // If we track sessions automaticall
        if repository.configuration.automaticSessionTracking {
            triggerEndSession()
        }
        
        switch flushingMode {
        case .periodic(_):
            // Invalidate the timer
            flushingTimer?.invalidate()
            flushingTimer = nil
            
            // Continue to flush data on line below
            fallthrough
            
        case .automatic, .immediate:
            flushData()
            
        default:
            break
        }
    }
    
    fileprivate var shouldTrackCurrentSession: Bool {
        /// Make sure a session was started
        guard sessionStartTime > 0 else {
            Exponea.logger.log(.warning, message: """
            Session not started - you need to first start a session before ending it.
            """)
            return false
        }
        
        // If current session didn't end yet, then we shouldn't track it
        guard sessionEndTime > 0 else {
            return false
        }
        
        /// Calculate the session duration
        let sessionDuration = sessionEndTime - sessionStartTime
        
        /// Session should be ended
        if sessionDuration > repository.configuration.sessionTimeout {
            return true
        } else {
            return false
        }
    }
    
    internal func trackStartSession(projectToken: String) throws {
        try database.trackEvent(with: [.projectToken(projectToken),
                                       .properties(device.properties),
                                       .eventType(Constants.EventTypes.sessionStart),
                                       .timestamp(sessionStartTime)])
    }
    
    fileprivate func triggerEndSession() {
        // Set the session end to the time when the app terminates
        sessionEndTime = Date().timeIntervalSince1970
        
        // Track session end (when terminating)
        do {
            try track(.sessionEnd, with: nil)
            
            // Reset session times
            sessionStartTime = 0
            sessionEndTime = 0
            
            Exponea.logger.log(.verbose, message: Constants.SuccessMessages.sessionEnd)
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
        }
    }
    
    internal func trackEndSession(projectToken: String) throws {
        /// Prepare data to persist into coredata.
        var properties = device.properties
        
        /// Calculate the duration of the last session.
        let duration = sessionEndTime - sessionStartTime
        
        /// Adding session end properties.
        properties["duration"] = .double(duration)
        
        try database.trackEvent(with: [.projectToken(projectToken),
                                       .properties(properties),
                                       .eventType(Constants.EventTypes.sessionEnd),
                                       .timestamp(sessionEndTime)])
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
            // Pull from db
            let events = try database.fetchTrackEvent().reversed()
            let customers = try database.fetchTrackCustomer().reversed()
            
            Exponea.logger.log(.verbose, message: """
                Flushing data: \(events.count + customers.count) total objects to upload, \
                \(events.count) events and \(customers.count) customer updates.
                """)
            
            // Check if we have any data, otherwise bail
            guard !events.isEmpty || !customers.isEmpty else {
                return
            }
            
            var customersDone = false
            var eventsDone = false
            
            flushCustomerTracking(Array(customers), completion: {
                customersDone = true
                if eventsDone && customersDone {
                    completion?()
                }
            })
            flushEventTracking(Array(events), completion: {
                eventsDone = true
                if eventsDone && customersDone {
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
                    Exponea.logger.log(.error, message: """
                        Failed to upload customer update. \(error.localizedDescription)
                        """)
                }
                
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
                    Exponea.logger.log(.error, message: "Failed to upload event. \(error.localizedDescription)")
                }
                
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
