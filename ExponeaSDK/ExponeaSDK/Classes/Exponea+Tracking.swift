//
//  Exponea+Tracking.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 28/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

extension Exponea {
    
    internal func executeWithDependencies(_ closure: (Exponea.Dependencies) throws -> Void) {
        do {
            let dependencies = try getDependenciesIfConfigured()
            try closure(dependencies)
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
        }
    }
    
    /// Adds new events to a customer. All events will be stored into coredata
    /// until it will be flushed (send to api).
    ///
    /// - Parameters:
    ///     - properties: Object with event values.
    ///     - timestamp: Unix timestamp when the event was created.
    ///     - eventType: Name of event
    public func trackEvent(properties: [String: JSONConvertible], timestamp: Double?, eventType: String?) {
        executeWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient("token, basic")
            }
            
            // Create initial data
            var data: [DataType] = [.properties(properties.mapValues({ $0.jsonValue })),
                                    .timestamp(timestamp)]
            
            // If event type was provided, use it
            if let eventType = eventType {
                data.append(.eventType(eventType))
            }
            
            // Do the actual tracking
            try dependencies.trackingManager.track(.customEvent, with: data)
        }
    }
    
    /// Adds new payment event to a customer.
    ///
    /// - Parameters:
    ///     - properties: Object with event values.
    ///     - timestamp: Unix timestamp when the event was created.
    public func trackPayment(properties: [String : JSONConvertible], timestamp: Double?) {
        executeWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient("token, basic")
            }
            
            // Create initial data
            let data: [DataType] = [.properties(properties.mapValues({ $0.jsonValue })),
                                    .timestamp(timestamp)]
            
            // Do the actual tracking
            try dependencies.trackingManager.track(.payment, with: data)
        }
    }
    
    /// Update the informed properties to a specific customer.
    /// All properties will be stored into coredata until it will be flushed (send to api).
    ///
    /// - Parameters:
    ///     - customerId: Specify your customer with external id, for example an email address.
    ///     - properties: Object with properties to be updated.
    ///     - timestamp: Unix timestamp when the event was created.
    public func identifyCustomer(customerIds: [String: JSONConvertible]?,
                                 properties: [String: JSONConvertible],
                                 timestamp: Double?) {
        executeWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient("token, basic")
            }
            
            // Prepare data
            var data: [DataType] = [.properties(properties.mapValues({ $0.jsonValue })),
                                    .timestamp(timestamp)]
            if var ids = customerIds {
                // Check for overriding cookie
                if ids["cookie"] != nil {
                    ids.removeValue(forKey: "cookie")
                    Exponea.logger.log(.warning, message: """
                    You should never set cookie ID directly on a customer. Ignoring.
                    """)
                }
                
                data.append(.customerIds(ids.mapValues({ $0.jsonValue })))
            }
            
            try dependencies.trackingManager.track(.identifyCustomer, with: data)
        }
    }
    
    // MARK: Push Notifications
    
    /// Tracks the push notification token to Exponea API with struct.
    ///
    /// - Parameter token: Token data.
    public func trackPushToken(_ token: Data) {
        // Convert token data to String
        trackPushToken(token.tokenString)
    }
    
    /// Tracks the push notification token to Exponea API with string.
    ///
    /// - Parameter token: String containing the push notification token.
    public func trackPushToken(_ token: String?) {
        executeWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient("token, basic")
            }
            let data: [DataType] = [.pushNotificationToken(token)]
            
            // Do the actual tracking
            try dependencies.trackingManager.track(.identifyCustomer, with: data)
        }
    }
    
    /// Tracks the push notification clicked event to Exponea API.
    public func trackPushOpened(with userInfo: [AnyHashable: Any]) {
        executeWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient("token, basic")
            }
            
            guard let payload = userInfo as? [String: Any] else {
                Exponea.logger.log(.error, message: "Push notification payload contained non-string keys.")
                return
            }
            
            var properties = JSONValue.convert(payload)
            properties["action_type"] = .string("notification")
            properties["status"] = .string("clicked")
            
            let data: [DataType] = [.timestamp(nil),
                                    .properties(properties)]
            // Do the actual tracking
            try dependencies.trackingManager.track(.pushOpened, with: data)
        }
    }
    
    // MARK: Sessions
    
    public func trackSessionStart() {
        executeWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient("token, basic")
            }
            try dependencies.trackingManager.triggerSessionStart()
        }
    }
    
    /// Tracks a
    public func trackSessionEnd() {
        executeWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient("token, basic")
            }
            try dependencies.trackingManager.triggerSessionEnd()
        }
    }
    
    // MARK: Flushing
    
    /// This method can be used to manually flush all available data to Exponea.
    public func flushData() {
        executeWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient("token, basic")
            }
            dependencies.trackingManager.flushData()
        }
    }
    
    // MARK: Anonymize
    
    /// Anonymizes the user and re-creates the database.
    /// All customer identification (inclduing cookie) will be permanently deleted.
    public func anonymize() {
        executeWithDependencies { dependencies in
            guard dependencies.configuration.authorization != Authorization.none else {
                throw ExponeaError.authorizationInsufficient("token, basic")
            }
            
            try dependencies.trackingManager.anonymize()
        }
    }
}
