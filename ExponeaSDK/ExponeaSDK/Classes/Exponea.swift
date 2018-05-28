//
//  Exponea.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 06/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// <#Description#>
public class Exponea {
    
    /// Shared instance of ExponeaSDK.
    public internal(set) static var shared = Exponea()
    
    /// A logger used to log all messages from the SDK.
    public static var logger: Logger = Logger()
    
    /// The configuration object containing all the configuration data necessary for Exponea SDK to work.
    ///
    /// The setter of this variable will setup all required tools and managers if the value is not nil,
    /// otherwise will deactivate everything. This can be useful if you want the user to be able to opt-out of
    /// Exponea tracking for example in a settings screen of your application.
    public internal(set) var configuration: Configuration? {
        get {
            guard let repository = repository else {
                return nil
            }
            
            return repository.configuration
        }
        
        set {
            guard let newValue = newValue else {
                Exponea.logger.log(.warning, message: "Removing Exponea configuration and resetting everything.")
                trackingManager = nil
                repository = nil
                return
            }
            
            if configuration != nil {
                Exponea.logger.log(.warning, message: "Resetting previous Exponea configuration.")
                trackingManager = nil
                repository = nil
            }
            
            // Initialise everything
            sharedInitializer(configuration: newValue)
        }
    }
    
    /// The manager responsible for all tracking, observing and processing data.
    internal var trackingManager: TrackingManagerType?
    
    /// Repository responsible for fetching or uploading data to the API.
    internal var repository: RepositoryType?
    
    /// Custom user defaults to track basic information
    internal var userDefaults: UserDefaults = {
        if UserDefaults(suiteName: "ExponeaSDK") == nil {
            UserDefaults.standard.addSuite(named: "ExponeaSDK")
        }
        return UserDefaults(suiteName: "ExponeaSDK")!
    }()
    
    /// Sets the flushing mode for usage
    public var flushingMode: FlushingMode {
        get {
            guard let trackingManager = trackingManager else {
                Exponea.logger.log(.warning, message: "Exponea not configured, falling back to manual flushing mode.")
                return .manual
            }
            
            return trackingManager.flushingMode
        }
        set {
            guard let trackingManager = trackingManager else {
                Exponea.logger.log(.warning, message: "Exponea not configured, can't set flushing mode.")
                return
            }
            
            trackingManager.flushingMode = newValue
        }
    }
    
    internal static let isBeingTested: Bool = {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }()
    
    // MARK: - Init -
    
    /// The initialiser is internal, so that only the singleton can exist.
    internal init() {}
    
    deinit {
        if !Exponea.isBeingTested {
            Exponea.logger.log(.error, message: "Exponea has deallocated. This should never happen.")
        }
    }
    
    internal func sharedInitializer(configuration: Configuration) {
        Exponea.logger.log(.verbose, message: "Intialising Exponea with provided configuration.")
        
        // Recreate repository
        let repository = ServerRepository(configuration: configuration)
        self.repository = repository
        
        // Setup tracking manager
        self.trackingManager = TrackingManager(repository: repository)
        
        // Do initial tracking if necessary
        trackInstallEvent()
    }
}

// MARK: - Tracking -

internal extension Exponea {
    
    /// Installation event is fired only once for the whole lifetime of the app on one
    /// device when the app is launched for the first time.
    internal func trackInstallEvent() {
        /// Checking if the APP was launched before.
        /// If the key value is false, means that the event was not fired before.
        guard !userDefaults.bool(forKey: Constants.Keys.launchedBefore) else {
            Exponea.logger.log(.verbose, message: "Install event was already tracked, skipping.")
            return
        }
        
        /// In case the event was not fired, we call the track manager
        /// passing the install event type.
        do {
            // Get depdencies and track install event
            let dependencies = try getDependenciesIfConfigured()
            try dependencies.trackingManager.track(.install, with: nil)
        
            /// Set the value to true if event was executed successfully
            userDefaults.set(true, forKey: Constants.Keys.launchedBefore)
            /// Set default timeout session time with default value
            userDefaults.set(Constants.Session.defaultTimeout, forKey: Constants.Keys.timeout)
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
        }
    }
    
    /// Alias for dependencies required across various internal and public functions of Exponea.
    internal typealias Dependencies = (
        configuration: Configuration,
        repository: RepositoryType,
        trackingManager: TrackingManagerType
    )
    
    /// <#Description#>
    ///
    /// - Returns: <#return value description#>
    /// - Throws: <#throws value description#>
    internal func getDependenciesIfConfigured() throws -> Dependencies {
        guard let configuration = configuration,
            let repository = repository,
            let trackingManager = trackingManager else {
                throw ExponeaError.notConfigured
        }
        return (configuration, repository, trackingManager)
    }
}

// MARK: - Public -

public extension Exponea {
    
    // MARK: - Configure -
    
    /// Initialize the configuration without a projectMapping (token mapping) for each type of event.
    ///
    /// - Parameters:
    ///   - projectToken: Project token to be used through the SDK.
    ///   - authorization: The authorization type used to authenticate with some Exponea endpoints.
    ///   - baseURL: Base URL used for the project, for example if you use a custom domain with your Exponea setup.
    public class func configure(projectToken: String, authorization: Authorization, baseURL: String? = nil) {
        do {
            let configuration = try Configuration(projectToken: projectToken,
                                                  authorization: authorization,
                                                  baseURL: baseURL)
            shared.configuration = configuration
        } catch {
            Exponea.logger.log(.error, message: "Can't create configuration: \(error.localizedDescription)")
        }
    }
    
    /// Initialize the configuration with a plist file containing the keys for the ExponeaSDK.
    ///
    /// - Parameters:
    ///   - plistName: Property list name containing the SDK setup keys
    ///
    /// Mandatory keys:
    ///  - projectToken: Project token to be used through the SDK, as a fallback to projectMapping.
    ///  - authorization: The authorization type used to authenticate with some Exponea endpoints.
    public class func configure(plistName: String) {
        do {
            let configuration = try Configuration(plistName: plistName)
            shared.configuration = configuration
        } catch {
            Exponea.logger.log(.error, message: """
                Can't parse Configuration from file \(plistName): \(error.localizedDescription).
                """)
        }
    }
    
    /// Initialize the configuration with a projectMapping (token mapping) for each type of event. This allows
    /// you to track events to multiple projects, even the same event to more project at once.
    ///
    /// - Parameters:
    ///   - projectToken: Project token to be used through the SDK, as a fallback to projectMapping.
    ///   - projectMapping: The project token mapping dictionary providing all the tokens.
    ///   - authorization: The authorization type used to authenticate with some Exponea endpoints.
    ///   - baseURL: Base URL used for the project, for example if you use a custom domain with your Exponea setup.
    public class func configure(projectToken: String,
                                projectMapping: [EventType: [String]],
                                authorization: Authorization,
                                baseURL: String? = nil) {
        do {
            let configuration = try Configuration(projectToken: projectToken,
                                                  projectMapping: projectMapping,
                                                  authorization: authorization,
                                                  baseURL: baseURL)
            shared.configuration = configuration
        } catch {
            Exponea.logger.log(.error, message: "Can't create configuration: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Tracking -
    
    /// Adds new events to a customer. All events will be stored into coredata
    /// until it will be flushed (send to api).
    ///
    /// - Parameters:
    ///     - properties: Object with event values.
    ///     - timestamp: Unix timestamp when the event was created.
    ///     - eventType: Name of event
    public class func trackEvent(properties: [AnyHashable: JSONConvertible], timestamp: Double?, eventType: String?) {
        // Create initial data
        var data: [DataType] = [.properties(properties),
                                .timestamp(timestamp)]
        
        // If event type was provided, use it
        if let eventType = eventType {
            data.append(.eventType(eventType))
        }
        
        do {
            // Get dependencies and do the actual tracking
            let dependencies = try shared.getDependenciesIfConfigured()
            try dependencies.trackingManager.track(.customEvent, with: data)
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
        }
    }
    
    /// This method can be used to manually flush all available data to Exponea.
    public class func flushData() {
        do {
            let dependencies = try shared.getDependenciesIfConfigured()
            dependencies.trackingManager.flushData()
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
        }
    }
    
    // MARK: Push Notifications
    
    /// Tracks the push notification token to Exponea API with struct.
    ///
    /// - Parameter token: Token data.
    public class func trackPushToken(_ token: Data) {
        // Convert token data to String
        trackPushToken(token.tokenString)
    }
    
    /// Tracks the push notification token to Exponea API with string.
    ///
    /// - Parameter token: String containing the push notification token.
    public class func trackPushToken(_ token: String) {
        let data: [DataType] = [.pushNotificationToken(token)]
        
        do {
            // Get dependencies and do the actual tracking
            let dependencies = try shared.getDependenciesIfConfigured()
            try dependencies.trackingManager.track(.identifyCustomer, with: data)
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
        }
    }
    
    /// Tracks the push notification clicked event to Exponea API.
    public class func trackPushClicked() {
        
    }
    
    // MARK: Sessions
    
    /// Restart any tasks that were paused (or not yet started) while the application was inactive.
    /// If the application was previously in the background, optionally refresh the user interface.
    public class func trackSessionStart() {
        do {
            let dependencies = try shared.getDependenciesIfConfigured()
            try dependencies.trackingManager.track(.sessionStart, with: nil)
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
        }
    }
    
    /// Restart any tasks that were paused (or not yet started) while the application was inactive.
    /// If the application was previously in the background, optionally refresh the user interface.
    public class func trackSessionEnd() {
        do {
            let dependencies = try shared.getDependenciesIfConfigured()
            try dependencies.trackingManager.track(.sessionEnd, with: nil)
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
    public class func updateCustomerProperties(customerId: String?,
                                               properties: [AnyHashable: JSONConvertible],
                                               timestamp: Double?) {
        do {
            let dependencies = try shared.getDependenciesIfConfigured()
            
            // Prepare data
            var data: [DataType] = [.properties(properties),
                                    .timestamp(timestamp)]
            if let id = customerId {
                data.append(.customerId(id))
            }
            
            try dependencies.trackingManager.track(.identifyCustomer, with: data)
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
        }
    }
    
    // MARK: Fetching
    
    /// Fetch all events for a specific customer
    ///
    /// - Parameters:
    ///     - customerId: Specify your customer with external id.
    ///     - events: Object containing all event types to be fetched.
    public class func fetchCustomerEvents(projectToken: String,
                                          customerId: [AnyHashable: JSONConvertible],
                                          events: EventsRequest,
                                          completion: @escaping (Result<EventsResponse>) -> Void) {
        do {
            let dependencies = try shared.getDependenciesIfConfigured()
            dependencies.repository.fetchEvents(projectToken: projectToken,
                                                customerId: customerId,
                                                events: events,
                                                completion: completion)
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
            completion(.failure(error))
        }
    }
    
    /// Fetch customer property
    ///
    /// - Parameters:
    ///     - customerId: Specify your customer with external id.
    ///     - events: Object containing all event types to be fetched.
    public class func fetchRecommendation(projectToken: String,
                                          customerId: [AnyHashable: JSONConvertible],
                                          recommendation: RecommendationRequest,
                                          completion: @escaping (Result<RecommendationResponse>) -> Void) {
        do {
            let dependencies = try shared.getDependenciesIfConfigured()
            dependencies.repository.fetchRecommendation(projectToken: projectToken,
                                                        customerId: customerId,
                                                        recommendation: recommendation,
                                                        completion: completion)
        } catch {
            Exponea.logger.log(.error, message: error.localizedDescription)
            completion(.failure(error))
        }
    }
}
