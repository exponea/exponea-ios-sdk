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
            // If we want to reset Exponea, warn about it and reset everything
            guard let newValue = newValue else {
                Exponea.logger.log(.warning, message: "Removing Exponea configuration and resetting everything.")
                trackingManager = nil
                repository = nil
                return
            }

            // If we want to re-configure Exponea, warn about it, reset everything and continue setting up with new
            if configuration != nil {
                Exponea.logger.log(.warning, message: "Resetting previous Exponea configuration.")
                trackingManager = nil
                repository = nil
            }

            // Initialise everything
            sharedInitializer(configuration: newValue)
        }
    }

    /// The manager responsible for tracking data and sessions.
    internal var trackingManager: TrackingManagerType?

    /// The manager responsible for flushing data to Exponea servers.
    internal var flushingManager: FlushingManagerType?

    /// Repository responsible for fetching or uploading data to the API.
    internal var repository: RepositoryType?

    /// Custom user defaults to track basic information
    internal var userDefaults: UserDefaults = {
        if UserDefaults(suiteName: Constants.General.userDefaultsSuite) == nil {
            UserDefaults.standard.addSuite(named: Constants.General.userDefaultsSuite)
        }
        return UserDefaults(suiteName: Constants.General.userDefaultsSuite)!
    }()

    /// Sets the flushing mode for usage
    public var flushingMode: FlushingMode {
        get {
            guard let flushingManager = flushingManager else {
                Exponea.logger.log(.warning, message: "Exponea not configured, falling back to manual flushing mode.")
                return .manual
            }

            return flushingManager.flushingMode
        }
        set {
            guard var flushingManager = flushingManager else {
                Exponea.logger.log(.warning, message: "Exponea not configured, can't set flushing mode.")
                return
            }

            flushingManager.flushingMode = newValue
        }
    }

    /// The delegate that gets callbacks about notification opens and/or actions. Only has effect if automatic
    /// push tracking is enabled, otherwise will never get called.
    public var pushNotificationsDelegate: PushNotificationManagerDelegate? {
        get {
            return trackingManager?.notificationsManager?.delegate
        }
        set {
            guard let notificationsManager = trackingManager?.notificationsManager else {
                Exponea.logger.log(
                    .warning,
                    message: "Cannot set push notifications delegate. " + Constants.ErrorMessages.sdkNotConfigured
                )
                return
            }
            notificationsManager.delegate = newValue
        }
    }

    internal static let isBeingTested: Bool = {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }()

    // Once ExponeaSDK runs into a NSException, all further calls will be disabled
    internal var nsExceptionRaised: Bool = false

    // MARK: - Init -

    /// The initialiser is internal, so that only the singleton can exist when used in production.
    internal init() {
        let version = Bundle(for: Exponea.self).infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        Exponea.logger.logMessage("⚙️ Starting ExponeaSDK, version \(version).")
    }

    deinit {
        if !Exponea.isBeingTested {
            Exponea.logger.log(.error, message: "Exponea has deallocated. This should never happen.")
        }
    }

    internal func sharedInitializer(configuration: Configuration) {
        Exponea.logger.log(.verbose, message: "Configuring Exponea with provided configuration:\n\(configuration)")
        let exception = objc_tryCatch {
            do {
                let database = try DatabaseManager()

                let repository = ServerRepository(configuration: configuration)
                self.repository = repository

                let flushingManager = try FlushingManager(
                    database: database,
                    repository: repository
                )
                self.flushingManager = flushingManager

                let trackingManager = try TrackingManager(
                    repository: repository,
                    database: database,
                    flushingManager: flushingManager,
                    userDefaults: userDefaults
                )

                self.trackingManager = trackingManager
                processSavedCampaignData()
            } catch {
                // Failing gracefully, if setup failed
                Exponea.logger.log(.error, message: """
                    Error while creating dependencies, Exponea cannot be configured.\n\(error.localizedDescription)
                    """)
            }
        }
        if let exception = exception {
            nsExceptionRaised = true
            Exponea.logger.log(.error, message: """
            Error while creating dependencies, Exponea cannot be configured.\n
            \(ExponeaError.nsExceptionRaised(exception).localizedDescription)
            """)
        }
    }
}

// MARK: - Dependencies + Safety wrapper -

internal extension Exponea {

    /// Alias for dependencies required across various internal and public functions of Exponea.
    typealias Dependencies = (
        configuration: Configuration,
        repository: RepositoryType,
        trackingManager: TrackingManagerType,
        flushingManager: FlushingManagerType
    )

    typealias CompletionHandler<T> = ((Result<T>) -> Void)
    typealias DependencyTask<T> = (Exponea.Dependencies, @escaping CompletionHandler<T>) throws -> Void

    /// Gets the Exponea dependencies. If Exponea wasn't configured it will throw an error instead.
    ///
    /// - Returns: The dependencies required to perform any actions.
    /// - Throws: A not configured error in case Exponea wasn't configured beforehand.
    func getDependenciesIfConfigured() throws -> Dependencies {
        guard let configuration = configuration,
            let repository = repository,
            let trackingManager = trackingManager,
            let flushingManager = flushingManager else {
                throw ExponeaError.notConfigured
        }
        return (configuration, repository, trackingManager, flushingManager)
    }

    func executeSafelyWithDependencies<T>(
        _ closure: DependencyTask<T>,
        completion: @escaping CompletionHandler<T>
    ) {
        if nsExceptionRaised {
            Exponea.logger.log(.error, message: ExponeaError.nsExceptionInconsistency.localizedDescription)
            completion(.failure(ExponeaError.nsExceptionInconsistency))
            return
        }
        let exception = objc_tryCatch {
            do {
                let dependencies = try getDependenciesIfConfigured()
                try closure(dependencies, completion)
            } catch {
                Exponea.logger.log(.error, message: error.localizedDescription)
                completion(.failure(error))
            }
        }
        if let exception = exception {
            nsExceptionRaised = true
            Exponea.logger.log(.error, message: ExponeaError.nsExceptionRaised(exception).localizedDescription)
            completion(.failure(ExponeaError.nsExceptionRaised(exception)))
        }
    }

    func executeSafelyWithDependencies(_ closure: (Exponea.Dependencies) throws -> Void) {
        executeSafelyWithDependencies({ dep, _ in try closure(dep) }, completion: {_ in } as CompletionHandler<Any>)
    }

    func executeSafely(_ closure: () throws -> Void) {
        if nsExceptionRaised {
            Exponea.logger.log(.error, message: ExponeaError.nsExceptionInconsistency.localizedDescription)
            return
        }
        let exception = objc_tryCatch {
            do {
                try closure()
            } catch {
                Exponea.logger.log(.error, message: error.localizedDescription)
            }
        }
        if let exception = exception {
            Exponea.logger.log(.error, message: ExponeaError.nsExceptionRaised(exception).localizedDescription)
            nsExceptionRaised = true
        }
    }
}

// MARK: - Public -

public extension Exponea {

    // MARK: - Configure -

    var isConfigured: Bool {
        return configuration != nil
            && repository != nil
            && trackingManager != nil
    }
    /// Initialize the configuration without a projectMapping (token mapping) for each type of event.
    ///
    /// - Parameters:
    ///   - projectToken: Project token to be used through the SDK.
    ///   - authorization: The authorization type used to authenticate with some Exponea endpoints.
    ///   - baseUrl: Base URL used for the project, for example if you use a custom domain with your Exponea setup.
    @available(*, deprecated)
    func configure(projectToken: String,
                   authorization: Authorization,
                   baseUrl: String? = nil,
                   appGroup: String? = nil,
                   defaultProperties: [String: JSONConvertible]? = nil) {
        do {
            let configuration = try Configuration(projectToken: projectToken,
                                                  authorization: authorization,
                                                  baseUrl: baseUrl,
                                                  appGroup: appGroup,
                                                  defaultProperties: defaultProperties)
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
    func configure(plistName: String) {
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
    ///   - baseUrl: Base URL used for the project, for example if you use a custom domain with your Exponea setup.
    @available(*, deprecated)
    func configure(projectToken: String,
                   projectMapping: [EventType: [String]],
                   authorization: Authorization,
                   baseUrl: String? = nil,
                   appGroup: String? = nil,
                   defaultProperties: [String: JSONConvertible]? = nil) {
        do {
            let configuration = try Configuration(projectToken: projectToken,
                                                  projectMapping: projectMapping,
                                                  authorization: authorization,
                                                  baseUrl: baseUrl,
                                                  appGroup: appGroup,
                                                  defaultProperties: defaultProperties)
            self.configuration = configuration
        } catch {
            Exponea.logger.log(.error, message: "Can't create configuration: \(error.localizedDescription)")
        }
    }
}
