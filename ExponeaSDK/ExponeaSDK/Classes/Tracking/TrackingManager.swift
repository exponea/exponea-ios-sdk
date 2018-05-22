//
//  TrackingManager.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 11/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

open class TrackingManager {
    let database: DatabaseManagerType
    let repository: RepositoryType
    let device: DeviceProperties
    
    /// Payment manager responsible to track all in app payments.
    internal var paymentManager: PaymentManagerType {
        didSet {
            paymentManager.delegate = self
            paymentManager.startObservingPayments()
        }
    }
    
    /// Used for periodic data flushing.
    internal var flushingTimer: Timer?
    public var flushingMode: FlushingMode = .automatic {
        didSet {
            Exponea.logger.log(.verbose, message: "Flushing mode updated to: \(flushingMode).")
            updateFlushingMode()
        }
    }
    
    init(repository: RepositoryType,
         database: DatabaseManagerType = DatabaseManager(),
         device: DeviceProperties = DeviceProperties(),
         paymentManager: PaymentManagerType = PaymentManager()) {
        self.repository = repository
        self.database = database
        self.device = device
        self.paymentManager = paymentManager
        
        initialSetup()
    }
    
    deinit {
        Exponea.logger.log(.verbose, message: "TrackingManager deallocated.")
        removeSessionObservers()
    }
    
    func initialSetup() {
        if repository.configuration.automaticSessionTracking {
            /// Add the observers when the automatic session tracking is true.
            addSessionObserves()
        } else {
            /// Remove the observers when the automatic session tracking is false.
            removeSessionObservers()
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
            }
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
}

// MARK: - Sessions

extension TrackingManager {
    internal var sessionStartTime: Double {
        get {
            return UserDefaults.standard.double(forKey: Constants.Keys.sessionStarted)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.Keys.sessionStarted)
        }
    }
    
    internal var sessionEndTime: Double {
        get {
            return UserDefaults.standard.double(forKey: Constants.Keys.sessionEnded)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.Keys.sessionEnded)
        }
    }
    
    /// Add observers to notification center in order to control when the
    /// app become active or enter in background.
    internal func addSessionObserves() {
        // Make sure we remove session observers first, if we are already observing.
        removeSessionObservers()
        
        // Subscribe to notifications
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive),
                                               name: .UIApplicationDidBecomeActive,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillResignActive),
                                               name: .UIApplicationWillResignActive,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillTerminate),
                                               name: .UIApplicationWillTerminate,
                                               object: nil)
    }
    
    /// Removes session observers.
    internal func removeSessionObservers() {
        NotificationCenter.default.removeObserver(self, name: .UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIApplicationWillTerminate, object: nil)
    }
    
    @objc internal func applicationDidBecomeActive() {
        // If this is first session start, then
        guard sessionStartTime != 0 else {
            sessionStartTime = Date().timeIntervalSince1970
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
                
                Exponea.logger.log(.verbose, message: Constants.SuccessMessages.sessionStart)
            } catch {
                Exponea.logger.log(.error, message: error.localizedDescription)
            }
        } else {
            Exponea.logger.log(.verbose, message: "Skipping tracking session end as within timeout or not started.")
        }
    }
    
    @objc internal func applicationWillResignActive() {
        // Set the session end to the time when the app resigns active state
        sessionEndTime = Date().timeIntervalSince1970
    }
    
    @objc internal func applicationWillTerminate() {
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
        let sessionDuration = sessionStartTime - sessionEndTime
        
        /// Session should be ended
        if sessionDuration > repository.configuration.sessionTimeout {
            return true
        } else {
            return false
        }
    }
    
    internal func trackStartSession(projectToken: String) throws {
        /// Prepare data to persist into coredata.
        var properties = device.properties
        /// Adding session start properties.
        properties.append(KeyValueItem(key: "event_type", value: Constants.EventTypes.sessionStart))
        properties.append(KeyValueItem(key: "timestamp", value: sessionStartTime))
        properties.append(KeyValueItem(key: "app_version", value: device.appVersion))
        
        try database.trackEvent(with: [.projectToken(projectToken),
                                       .properties(properties),
                                       .eventType(Constants.EventTypes.sessionStart)])
    }
    
    internal func trackEndSession(projectToken: String) throws {
        /// Prepare data to persist into coredata.
        var properties = device.properties
        /// Calculate the duration of the last session.
        let duration = sessionStartTime - sessionEndTime
        /// Adding session end properties.
        properties.append(KeyValueItem(key: "event_type", value: Constants.EventTypes.sessionStart))
        properties.append(KeyValueItem(key: "timestamp", value: sessionEndTime))
        properties.append(KeyValueItem(key: "duration", value: duration))
        properties.append(KeyValueItem(key: "app_version", value: device.appVersion))
        
        try database.trackEvent(with: [.projectToken(projectToken),
                                       .properties(properties),
                                       .eventType(Constants.EventTypes.sessionEnd)])
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
        
        Exponea.logger.log(.verbose, message: "Flushing data now.")
        
        // Pull from db
        do {
            let events = try database.fetchTrackEvent()
            let customers = try database.fetchTrackCustomer()
            
            // Check if we have any data, otherwise bail
            guard !events.isEmpty || !customers.isEmpty else {
                return
            }
        
            for event in events {
                Exponea.logger.log(.verbose, message: "Uploading event: \(event.objectID).")
                
                repository.trackEvent(with: event.dataTypes, for: database.customer) { [weak self] (result) in
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
                }
                
            }
    
//            for customer in customers {
    
//            }
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
        }
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
