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
    let database: DatabaseManager
    /// Payment manager to responsable to track all in app payments
    let paymentManager: PaymentManager

    /// Boolean identifier that returns if the SDK is configured or not.
    public var configured: Bool {
        if configuration.projectToken != nil {
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
                fatalError(Constants.ErrorMessages.sdkNotConfigured)
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

    /// Sets the flushing mode for usage
    public var flushingMode: FlushingMode {
        get {
            return trackingManager.flushingMode
        }
        set {
            trackingManager.flushingMode = newValue
        }
    }

    /// A logger used to log all messages from the SDK.
    public static var logger: Logger = Logger()

    /// Shared instance of ExponeaSDK
    public static let shared = Exponea()

    let trackingManager: TrackingManager

    init(repository: TrackingRepository) {
        /// SDK configuration.
        self.configuration = Configuration()
        /// Initialing database manager with specific container.
        self.database = DatabaseManager()
        /// Initializing tracking manager.
        self.trackingManager = TrackingManager(database: database,
                                               repository: repository,
                                               configuration: self.configuration)
        /// Initializing payment manager.
        self.paymentManager = PaymentManager(trackingMananger: self.trackingManager)
    }

    public init() {
        /// SDK configuration.
        self.configuration = Configuration()
        /// Initializing database manager with default container
        self.database = DatabaseManager()
        /// API configuration.
        let apiConfiguration = APIConfiguration(baseURL: Constants.Repository.baseURL,
                                             contentType: Constants.Repository.contentType)
        /// Initializing repository.
        let repository = ConnectionManager(configuration: apiConfiguration)
        /// Initializing tracking manager.
        self.trackingManager = TrackingManager(database: self.database,
                                               repository: repository,
                                               configuration: self.configuration)
        /// Initializing payment manager.
        self.paymentManager = PaymentManager(trackingMananger: self.trackingManager)
    }

    deinit {
        removeObservers()
    }
}

internal extension Exponea {
    internal func configure(projectToken: String) {
        configuration = Configuration(projectToken: projectToken)
    }

    internal func configure(plistName: String) {
        configuration = Configuration(plistName: plistName)
    }

    internal func sharedInitializer() {
        trackInstallEvent()
        paymentManager.listenPayments()
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
}

public extension Exponea {
    /// Initialize the configuration with a projectId (token)
    ///
    /// - Parameters:
    ///     - projectToken: Project Token to be used through the SDK
    public class func configure(projectToken: String) {
        shared.configure(projectToken: projectToken)
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
}
