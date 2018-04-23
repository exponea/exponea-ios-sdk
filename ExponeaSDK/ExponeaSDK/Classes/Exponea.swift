//
//  Exponea.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 06/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

public class Exponea {

    /// The configuration object containing all the config data for the shared instance.
    fileprivate(set) var configuration: Configuration!
    /// Database manager responsable for data persistance.
    let database: DatabaseManagerType
    /// Payment manager responsable to track all in app payments
    let paymentManager: PaymentManagerType
    /// Repository responsable for http requests.
    let repository: ConnectionManagerType

    /// Boolean identifier that returns if the SDK is configured or not.
    public var configured: Bool {
        if configuration.projectToken != nil && configuration.authorization != nil {
            return true
        }
        return false
    }
    /// Identification of the project
    public var projectToken: String? {
        get {
            return configuration.projectToken
        }
        set {
            guard configured else {
                Exponea.logger.log(.error, message: Constants.ErrorMessages.sdkNotConfigured)
                return
            }
            configuration.projectToken = newValue
        }
    }
    /// Default timeout value for tracking the sessions
    public var sessionTimeout: Double {
        get {
            return configuration.sessionTimeout
        }
        set {
            configuration.sessionTimeout = newValue
        }
    }
    /// Default value for tracking the sessions automatically
    public var autoSessionTracking: Bool {
        get {
            return configuration.autoSessionTracking
        }
        set {
            configuration.autoSessionTracking = newValue
            /// Add the observers when the automatic session tracking is true.
            if newValue {
                addSessionObserves()
            }
            /// Remove the observers when the automatic session tracking is false.
            else {
                removeObservers()
            }
        }
    }
    /// Authorization header for authentication using the exponea access tokens.
    public var authorization: String? {
        get {
            return configuration.authorization
        }
        set {
            configuration.authorization = newValue
        }
    }
    /// Sets the flushing mode for usage
    public var flushingMode: FlushingMode {
        get {
            return trackingManager.flushingMode
        }
        set {
            trackingManager.flushingMode = newValue
        }
    }
    /// Sets the base url for the project in exponea app
    public var baseURL: String {
        get {
            return configuration.baseURL
        }
        set {
            configuration.baseURL = newValue
        }
    }

    /// A logger used to log all messages from the SDK.
    public static var logger: Logger = Logger()

    /// Shared instance of ExponeaSDK
    public static let shared = Exponea()

    let trackingManager: TrackingManager

    init(database: DatabaseManagerType,
         repository: ConnectionManagerType) {
        /// SDK configuration.
        self.configuration = Configuration()
        /// Initialing database manager
        self.database = database
        /// Initializing repository.
        self.repository = repository
        /// Initializing tracking manager.
        self.trackingManager = TrackingManager(database: database,
                                               configuration: self.configuration)
        /// Initializing payment manager.
        self.paymentManager = PaymentManager(trackingMananger: self.trackingManager)
    }

    public init() {
        /// SDK configuration.
        self.configuration = Configuration()
        /// Initializing database manager
        self.database = DatabaseManager()
        /// Initializing repository.
        self.repository = ConnectionManager(configuration: self.configuration)
        /// Initializing tracking manager.
        self.trackingManager = TrackingManager(database: self.database,
                                               configuration: self.configuration)
        /// Initializing payment manager.
        self.paymentManager = PaymentManager(trackingMananger: self.trackingManager)
    }

    deinit {
        removeObservers()
    }
}

internal extension Exponea {
    internal func configure(projectToken: String, authorization: String, baseURL: String?) {
        configuration = Configuration(projectToken: projectToken,
                                      authorization: authorization,
                                      baseURL: baseURL)
    }

    internal func configure(plistName: String) {
        configuration = Configuration(plistName: plistName)
    }

    internal func sharedInitializer() {
        trackInstallEvent()
        paymentManager.startObservingPayments()
    }

    /// Installation event is fired only once for the whole lifetime of the app on one
    /// device when the app is launched for the first time.
    internal func trackInstallEvent() {
        /// Checking if the APP was launched before.
        /// If the key value is false, means that the event was not fired before.
        guard !UserDefaults.standard.bool(forKey: Constants.Keys.launchedBefore) else {
            return
        }
        /// In case the event was not fired, we call the track manager
        /// passing the install event type.
        guard trackingManager.trackEvent(.install, customData: nil) else {
            return
        }
        /// Set the value to true if event was executed successfully
        UserDefaults.standard.set(true, forKey: Constants.Keys.launchedBefore)
        /// Set default timeout session time with default value
        UserDefaults.standard.set(Constants.Session.defaultTimeout, forKey: Constants.Keys.timeout)
        /// Seting the automatic session tracking default value
        autoSessionTracking = true
    }

    /// Send data to trackmanager to store the customer events into coredata
    internal func trackEvent(customerId: KeyValueModel,
                             properties: [KeyValueModel],
                             timestamp: Double?,
                             eventType: String?) -> Bool {
        var data: [DataType] = [.customerId(customerId),
                                .properties(properties),
                                .timestamp(timestamp)]

        if let eventType = eventType {
            data.append(.eventType(eventType))
        }

        return trackingManager.trackEvent(.trackEvent, customData: data)
    }

    @objc internal func trackSessionStart() {
        if trackingManager.trackEvent(.sessionStart, customData: nil) {
            Exponea.logger.log(.verbose, message: Constants.SuccessMessages.sessionStarted)
        }
    }

    @objc internal func trackSessionEnd() {
        configuration.lastSessionEndend = NSDate().timeIntervalSince1970
    }

    /// This method can be used to manually flush all available data to Exponea.
    internal func flushData() {
        trackingManager.flushData()
    }

    /// Add observers to notification center in order to control when the
    /// app become active or enter in background.
    internal func addSessionObserves() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(trackSessionStart),
                                               name: .UIApplicationDidBecomeActive,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(trackSessionEnd),
                                               name: .UIApplicationDidEnterBackground,
                                               object: nil)
    }

    internal func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }

    /// Send data to trackmanager to store the customer properties into coredata
    internal func trackCustomer(customerId: KeyValueModel,
                                properties: [KeyValueModel],
                                timestamp: Double?) -> Bool {
        return trackingManager.trackEvent(.trackCustomer,
                                          customData: [.customerId(customerId),
                                                       .properties(properties),
                                                       .timestamp(timestamp)])
    }

    /// Request customer events from the repository
    internal func fetchEvents(customerId: KeyValueModel,
                              events: CustomerEvents,
                              completion: @escaping (Result<Events>) -> Void ) {
        guard let projectToken = projectToken else {
            return
        }
        repository.fetchEvents(projectToken: projectToken,
                               customerId: customerId,
                               events: events,
                               completion: completion)
    }

    /// Request customer recommendations from the repository
    internal func fetchRecommendation(customerId: KeyValueModel,
                                      recommendation: CustomerRecommendation,
                                      completion: @escaping (Result<Recommendation>) -> Void ) {
        guard let projectToken = projectToken else {
            return
        }
        repository.fetchRecommendation(projectToken: projectToken,
                                       customerId: customerId,
                                       recommendation: recommendation,
                                       completion: completion)
    }
}

public extension Exponea {
    /// Initialize the configuration with a projectId (token)
    ///
    /// - Parameters:
    ///     - projectToken: Project Token to be used through the SDK
    public class func configure(projectToken: String, authorization: String, baseURL: String?) {
        shared.configure(projectToken: projectToken, authorization: authorization, baseURL: baseURL)
        shared.sharedInitializer()
    }

    /// Initialize the configuration with a plist file containing the keys
    /// for the ExponeaSDK
    /// Mandatory key: exponeaProjectIdKey
    ///
    /// - Parameters:
    ///     - plistName: List name containing the SDK setup keys
    public class func configure(plistName: String) {
        shared.configure(plistName: plistName)
        shared.sharedInitializer()
    }

    /// Track customer event add new events to a specific customer.
    /// All events will be stored into coredata until it will be
    /// flushed (send to api).
    ///
    /// - Parameters:
    ///     - customerId: Specify your customer with external id.
    ///     - properties: Object with event values.
    ///     - timestamp: Unix timestamp when the event was created.
    ///     - eventType: Name of event
    public class func trackCustomerEvent(customerId: KeyValueModel,
                                         properties: [KeyValueModel],
                                         timestamp: Double?,
                                         eventType: String) -> Bool {
        return shared.trackEvent(customerId: customerId,
                                 properties: properties,
                                 timestamp: timestamp,
                                 eventType: eventType)
    }

    /// Restart any tasks that were paused (or not yet started) while the application was inactive.
    /// If the application was previously in the background, optionally refresh the user interface.
    ///
    public class func trackSessionStart() {
        shared.trackSessionStart()
    }

    /// Restart any tasks that were paused (or not yet started) while the application was inactive.
    /// If the application was previously in the background, optionally refresh the user interface.
    ///
    public class func trackSessionEnd() {
        shared.trackSessionEnd()
    }

    /// Update the informed properties to a specific customer.
    /// All properties will be stored into coredata until it will be
    /// flushed (send to api).
    ///
    /// - Parameters:
    ///     - customerId: Specify your customer with external id.
    ///     - properties: Object with properties to be updated.
    ///     - timestamp: Unix timestamp when the event was created.
    public class func updateCustomerProperties(customerId: KeyValueModel,
                                               properties: [KeyValueModel],
                                               timestamp: Double?) -> Bool {
        return shared.trackCustomer(customerId: customerId,
                                    properties: properties,
                                    timestamp: timestamp)
    }

    /// This method can be used to manually flush all available data to Exponea.
    public class func flushData() {
        shared.flushData()
    }

    /// Fetch all events for a specific customer
    ///
    /// - Parameters:
    ///     - customerId: Specify your customer with external id.
    ///     - events: Object containing all event types to be fetched.
    public class func fetchCustomerEvents(customerId: KeyValueModel,
                                          events: CustomerEvents,
                                          completion: @escaping (Result<Events>) -> Void) {
        shared.fetchEvents(customerId: customerId,
                           events: events,
                           completion: completion)
    }

    /// Fetch customer property
    ///
    /// - Parameters:
    ///     - customerId: Specify your customer with external id.
    ///     - events: Object containing all event types to be fetched.
    public class func fetchCustomerProperty(customerId: KeyValueModel,
                                            recommendation: CustomerRecommendation,
                                            completion: @escaping (Result<Recommendation>) -> Void) {
        shared.fetchRecommendation(customerId: customerId,
                                   recommendation: recommendation,
                                   completion: completion)
    }
}
