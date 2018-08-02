//
//  Exponea+Tracking.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 28/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

extension Exponea {
    
    /// Adds new events to a customer. All events will be stored into coredata
    /// until it will be flushed (send to api).
    ///
    /// - Parameters:
    ///     - properties: Object with event values.
    ///     - timestamp: Unix timestamp when the event was created.
    ///     - eventType: Name of event
    public func trackEvent(properties: [String: JSONConvertible], timestamp: Double?, eventType: String?) {
        // Create initial data
        var data: [DataType] = [.properties(properties.mapValues({ $0.jsonValue })),
                                .timestamp(timestamp)]
        
        // If event type was provided, use it
        if let eventType = eventType {
            data.append(.eventType(eventType))
        }
        
        do {
            // Get dependencies and do the actual tracking
            let dependencies = try getDependenciesIfConfigured()
            try dependencies.trackingManager.track(.customEvent, with: data)
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
        }
    }
    
    /// Adds new payment event to a customer.
    ///
    /// - Parameters:
    ///     - properties: Object with event values.
    ///     - timestamp: Unix timestamp when the event was created.
    public func trackPayment(properties: [String : JSONConvertible], timestamp: Double?) {
        // Create initial data
        let data: [DataType] = [.properties(properties.mapValues({ $0.jsonValue })),
                                .timestamp(timestamp)]
        
        do {
            // Get dependencies and do the actual tracking
            let dependencies = try getDependenciesIfConfigured()
            try dependencies.trackingManager.track(.payment, with: data)
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
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
        do {
            let dependencies = try getDependenciesIfConfigured()
            
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
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
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
    public func trackPushToken(_ token: String) {
        let data: [DataType] = [.pushNotificationToken(token)]
        
        do {
            // Get dependencies and do the actual tracking
            let dependencies = try getDependenciesIfConfigured()
            try dependencies.trackingManager.track(.identifyCustomer, with: data)
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
        }
    }
    
    /// Tracks the push notification clicked event to Exponea API.
    public func trackPushOpened(with userInfo: [AnyHashable: Any]) {
        let data: [DataType] = [.timestamp(nil), .pushNotificationPayload(userInfo)]
        
        do {
            // Get dependencies and do the actual tracking
            let dependencies = try getDependenciesIfConfigured()
            try dependencies.trackingManager.track(.pushOpened, with: data)
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
        }
        
    }
    
    // MARK: Sessions
    
    public func trackSessionStart() {
        do {
            let dependencies = try getDependenciesIfConfigured()
            try dependencies.trackingManager.triggerSessionStart()
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
        }
    }
    
    /// Tracks a
    public func trackSessionEnd() {
        do {
            let dependencies = try getDependenciesIfConfigured()
            try dependencies.trackingManager.triggerSessionEnd()
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
        }
    }
    
    // MARK: Flushing
    
    /// This method can be used to manually flush all available data to Exponea.
    public func flushData() {
        do {
            let dependencies = try getDependenciesIfConfigured()
            dependencies.trackingManager.flushData()
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
        }
    }
}
