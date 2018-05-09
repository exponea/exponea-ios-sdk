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
    
    // FIXME: FIX
    let customer: Customer = Customer(id: UUID())
    
    /// Used for periodic data flushing
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
        
        // TODO: Refactor
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
        
        // FIXME: Refactor the success tracking and add more logging.
        
        /// For each project token we have, track the data.
        for projectToken in tokens {
            let payload: [DataType] = [.projectToken(projectToken)] + (data ?? [])
            
            switch type {
            case .install:
                try installEvent(projectToken: projectToken)
            case .sessionStart:
                try sessionStart(projectToken: projectToken)
            case .sessionEnd:
                // TODO: save to db
                throw TrackingManagerError.unknownError("Not implemented")
            case .trackEvent:
                try trackEvent(with: payload)
            case .trackCustomer:
                try trackCustomer(with: payload)
            case .payment:
                try trackPayment(with: payload + [.eventType(Constants.EventTypes.payment)])
            }
        }
    }
}

extension TrackingManager {
    open func installEvent(projectToken: String) throws {
        try database.trackEvent(with: [.projectToken(projectToken),
                                       .properties(device.properties),
                                       .eventType(Constants.EventTypes.installation)])
    }
    
    open func trackEvent(with data: [DataType]) throws {
        try database.trackEvent(with: data)
    }
    
    open func trackCustomer(with data: [DataType]) throws {
        try database.trackCustomer(with: data)
    }
    
    open func trackPayment(with data: [DataType]) throws {
        try database.trackEvent(with: data)
    }
    
    open func sessionStart(projectToken: String) throws {
        /// Get the current timestamp to calculate the session period.
        let now = Date().timeIntervalSince1970
        
        /// Check the status of the previous session.
        if sessionEnded(newTimestamp: now, projectToken: projectToken) {
            /// Update the new session value.
            currentSessionStart = now
            
            // Restart the session
            try trackEndSession(projectToken: projectToken)
            try trackStartSession(projectToken: projectToken)
        } else {
            currentSessionStart = now
            try trackStartSession(projectToken: projectToken)
        }
    }
}

// MARK: - Sessions

extension TrackingManager {
    internal var currentSessionStart: Double {
        get {
            let time = UserDefaults.standard.double(forKey: Constants.Keys.sessionStarted)
            return time == 0 ? NSDate().timeIntervalSince1970 : time
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.Keys.sessionStarted)
        }
    }
    internal var currentSessionEnd: Double {
        get {
            let time = UserDefaults.standard.double(forKey: Constants.Keys.sessionEnded)
            return time == 0 ? NSDate().timeIntervalSince1970 : time
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
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(trackSessionStart),
                                               name: .UIApplicationDidBecomeActive,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(trackSessionEnd),
                                               name: .UIApplicationDidEnterBackground,
                                               object: nil)
    }
    
    /// Removes session observers.
    internal func removeSessionObservers() {
        NotificationCenter.default.removeObserver(self, name: .UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIApplicationDidBecomeActive, object: nil)
    }
    
    @objc internal func trackSessionStart() {
        do {
            try track(.sessionStart, with: nil)
            Exponea.logger.log(.verbose, message: Constants.SuccessMessages.sessionStart)
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
        }
    }
    
    @objc internal func trackSessionEnd() {
        do {
            try track(.sessionEnd, with: nil)
            Exponea.logger.log(.verbose, message: Constants.SuccessMessages.sessionEnd)
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
        }
    }
}

extension TrackingManager {
    fileprivate func sessionEnded(newTimestamp: Double, projectToken: String) -> Bool {
        /// Check only if session has ended before
        guard currentSessionEnd > 0 else {
            return false
        }
        
        /// Calculate the session duration
        let sessionDuration = newTimestamp - currentSessionEnd
        
        /// Session should be ended
        if sessionDuration > repository.configuration.sessionTimeout {
            return true
        } else {
            return false
        }
    }
    
    fileprivate func trackStartSession(projectToken: String) throws {
        /// Prepare data to persist into coredata.
        var properties = device.properties
        /// Adding session start properties.
        properties.append(KeyValueItem(key: "event_type", value: Constants.EventTypes.sessionStart))
        properties.append(KeyValueItem(key: "timestamp", value: currentSessionStart))
        properties.append(KeyValueItem(key: "app_version", value: device.appVersion))
        
        try database.trackEvent(with: [.projectToken(projectToken),
                                       .properties(properties),
                                       .eventType(Constants.EventTypes.sessionStart)])
    }
    
    fileprivate func trackEndSession(projectToken: String) throws {
        /// Prepare data to persist into coredata.
        var properties = device.properties
        /// Calculate the duration of the last session.
        let duration = currentSessionStart - currentSessionEnd
        /// Adding session end properties.
        properties.append(KeyValueItem(key: "event_type", value: Constants.EventTypes.sessionStart))
        properties.append(KeyValueItem(key: "timestamp", value: currentSessionEnd))
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
        
        // Pull from db
        do {
            let events = try database.fetchTrackEvent()
            let customers = try database.fetchTrackCustomer()
            
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
