//
//  Exponea.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 06/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

public class Exponea: ExponeaType {
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
    public func configure(projectToken: String, authorization: Authorization, baseURL: String? = nil) {
        do {
            let configuration = try Configuration(projectToken: projectToken,
                                                  authorization: authorization,
                                                  baseURL: baseURL)
            self.configuration = configuration
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
    public func configure(plistName: String) {
        do {
            let configuration = try Configuration(plistName: plistName)
            self.configuration = configuration
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
    public func configure(projectToken: String,
                          projectMapping: [EventType: [String]],
                          authorization: Authorization,
                          baseURL: String? = nil) {
        do {
            let configuration = try Configuration(projectToken: projectToken,
                                                  projectMapping: projectMapping,
                                                  authorization: authorization,
                                                  baseURL: baseURL)
            self.configuration = configuration
        } catch {
            Exponea.logger.log(.error, message: "Can't create configuration: \(error.localizedDescription)")
        }
    }
}
