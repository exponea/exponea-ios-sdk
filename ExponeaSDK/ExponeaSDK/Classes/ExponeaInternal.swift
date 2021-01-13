//
//  ExponeaInternal.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 06/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
#if !COCOAPODS
import ExponeaSDKObjC
#endif

extension Exponea {
    /// Shared instance of ExponeaSDK.
    public internal(set) static var shared = ExponeaInternal()

    internal static let isBeingTested: Bool = {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }()
}

public class ExponeaInternal: ExponeaType {

    /// The configuration object containing all the configuration data necessary for Exponea SDK to work.
    ///
    /// The setter of this variable will setup all required tools and managers.
    /// Exponea can only be configured once.
    public internal(set) var configuration: Configuration? {
        get {
            guard let repository = repository else {
                return nil
            }

            return repository.configuration
        }

        set {
            guard let newValue = newValue else {
                Exponea.logger.log(.error, message: "Configuration cannot be set to nil.")
                return
            }

            guard configuration == nil || Exponea.isBeingTested else {
                Exponea.logger.log(.error, message: "Exponea SDK already configured.")
                return
            }

            // Initialise everything
            sharedInitializer(configuration: newValue)
        }
    }

    /// Cookie of the current customer. Nil before the SDK is configured
    public var customerCookie: String? {
        return trackingManager?.customerCookie
    }

    /// The manager responsible for tracking data and sessions.
    internal var trackingManager: TrackingManagerType?

    /// The manager responsible for flushing data to Exponea servers.
    internal var flushingManager: FlushingManagerType?

    /// The manager responsible for preloading and showing in-app messages.
    internal var inAppMessagesManager: InAppMessagesManagerType?

    /// Repository responsible for fetching or uploading data to the API.
    internal var repository: RepositoryType?

    internal var telemetryManager: TelemetryManager?

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
                Exponea.logger.log(
                    .warning,
                    message: "Falling back to manual flushing mode. " + Constants.ErrorMessages.sdkNotConfigured
                )
                return .manual
            }

            return flushingManager.flushingMode
        }
        set {
            guard var flushingManager = flushingManager else {
                Exponea.logger.log(
                    .warning,
                    message: "Cannot set flushing mode. " + Constants.ErrorMessages.sdkNotConfigured
                )
                return
            }

            flushingManager.flushingMode = newValue
        }
    }

    /// The delegate that gets callbacks about notification opens and/or actions. Only has effect if automatic
    /// push tracking is enabled, otherwise will never get called.
    public var pushNotificationsDelegate: PushNotificationManagerDelegate? {
        get {
            return trackingManager?.notificationsManager.delegate
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

    /// Default properties to be tracked with all events.
    /// Provide default properties when calling Exponea.shared.configure, they're exposed here for run-time changing.
    public var defaultProperties: [String: JSONConvertible]? {
        get {
            return repository?.configuration.defaultProperties
        }
        set {
            guard let repository = repository else {
                Exponea.logger.log(.warning, message: "Cannot set default properties before Exponea is configured.")
                return
            }
            repository.configuration.defaultProperties = newValue
        }
    }

    /// Any NSException inside Exponea SDK will be logged and swallowed if flag is enabled, otherwise
    /// the exception will be rethrown.
    /// Safemode is enabled for release builds and disabled for debug builds.
    /// You can set the value to override this behavior for e.g. unit testing.
    /// We advice strongly against disabling this for production builds.
    public var safeModeEnabled: Bool {
        get {
            if let override = safeModeOverride {
                return override
            }
            var enabled = true
            inDebugBuild { enabled = false }
            return enabled
        }
        set { safeModeOverride = newValue }
    }
    private var safeModeOverride: Bool?

    /// Once ExponeaSDK runs into a NSException, all further calls will be disabled
    internal var nsExceptionRaised: Bool = false

    internal var pushNotificationSelfCheck: PushNotificationSelfCheck?

    /// To help developers with integration, we can automatically check push notification setup
    /// when application is started in debug mode.
    /// When integrating push notifications(or when testing), we
    /// advise you to turn this feature on before initializing the SDK.
    /// Self-check only runs in debug mode and does not do anything in release builds.
    public var checkPushSetup: Bool = false

    // MARK: - Init -

    /// The initialiser is internal, so that only the singleton can exist when used in production.
    internal init() {
        Exponea.logger.logMessage("⚙️ Starting ExponeaSDK, version \(Exponea.version).")
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
                if !Exponea.isBeingTested {
                    telemetryManager = TelemetryManager(
                        userDefaults: userDefaults,
                        userId: database.currentCustomer.uuid.uuidString
                    )
                    telemetryManager?.start()
                    telemetryManager?.report(initEventWithConfiguration: configuration)
                    let eventCount = try database.countTrackCustomer() + (try database.countTrackEvent())
                    telemetryManager?.report(
                        eventWithType: .eventCount,
                        properties: ["count": String(describing: eventCount)])
                }

                let repository = ServerRepository(configuration: configuration)
                self.repository = repository

                let flushingManager = try FlushingManager(
                    database: database,
                    repository: repository,
                    customerIdentifiedHandler: { [weak self] in
                        // reload in-app messages once customer identification is flushed - user may have been merged
                        guard let inAppMessagesManager = self?.inAppMessagesManager,
                              let trackingManager = self?.trackingManager else { return }
                        inAppMessagesManager.preload(for: trackingManager.customerIds)
                    }
                )
                self.flushingManager = flushingManager

                let inAppMessagesManager = InAppMessagesManager(
                   repository: repository,
                   displayStatusStore: InAppMessageDisplayStatusStore(userDefaults: userDefaults)
                )
                self.inAppMessagesManager = inAppMessagesManager

                let trackingManager = try TrackingManager(
                    repository: repository,
                    database: database,
                    flushingManager: flushingManager,
                    inAppMessagesManager: inAppMessagesManager,
                    userDefaults: userDefaults
                )

                self.trackingManager = trackingManager
                processSavedCampaignData()

                configuration.saveToUserDefaults()
            } catch {
                telemetryManager?.report(error: error, stackTrace: Thread.callStackSymbols)
                // Failing gracefully, if setup failed
                Exponea.logger.log(.error, message: """
                    Error while creating dependencies, Exponea cannot be configured.\n\(error.localizedDescription)
                    """)
            }
        }
        if let exception = exception {
            nsExceptionRaised = true
            telemetryManager?.report(exception: exception)
            Exponea.logger.log(.error, message: """
            Error while creating dependencies, Exponea cannot be configured.\n
            \(ExponeaError.nsExceptionRaised(exception).localizedDescription)
            """)
        }
    }
}

// MARK: - Dependencies + Safety wrapper -

internal extension ExponeaInternal {

    /// Alias for dependencies required across various internal and public functions of Exponea.
    typealias Dependencies = (
        configuration: Configuration,
        repository: RepositoryType,
        trackingManager: TrackingManagerType,
        flushingManager: FlushingManagerType
    )

    typealias CompletionHandler<T> = ((Result<T>) -> Void)
    typealias DependencyTask<T> = (ExponeaInternal.Dependencies, @escaping CompletionHandler<T>) throws -> Void

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
        executeSafely({
                let dependencies = try getDependenciesIfConfigured()
                try closure(dependencies, completion)
            },
            errorHandler: { error in completion(.failure(error)) }
        )
    }

    func executeSafelyWithDependencies(_ closure: (ExponeaInternal.Dependencies) throws -> Void) {
        executeSafelyWithDependencies({ dep, _ in try closure(dep) }, completion: { _ in } as CompletionHandler<Any>)
    }

    func executeSafely(_ closure: () throws -> Void) {
        executeSafely(closure, errorHandler: nil)
    }

    func executeSafely(_ closure: () throws -> Void, errorHandler: ((Error) -> Void)?) {
        if nsExceptionRaised {
            Exponea.logger.log(.error, message: ExponeaError.nsExceptionInconsistency.localizedDescription)
            errorHandler?(ExponeaError.nsExceptionInconsistency)
            return
        }
        let exception = objc_tryCatch {
            do {
                try closure()
            } catch {
                Exponea.logger.log(.error, message: error.localizedDescription)
                telemetryManager?.report(error: error, stackTrace: Thread.callStackSymbols)
                errorHandler?(error)
            }
        }
        if let exception = exception {
            telemetryManager?.report(exception: exception)
            Exponea.logger.log(.error, message: ExponeaError.nsExceptionRaised(exception).localizedDescription)
            if safeModeEnabled {
                nsExceptionRaised = true
                errorHandler?(ExponeaError.nsExceptionRaised(exception))
            } else {
                Exponea.logger.log(.error, message: "Re-raising caugth NSException in debug build.")
                exception.raise()
            }
        }
    }
}

// MARK: - Public -

public extension ExponeaInternal {

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
    ///   - projectMapping: The project mapping dictionary providing all the tokens.
    ///   - authorization: The authorization type used to authenticate with some Exponea endpoints.
    ///   - baseUrl: Base URL used for the project, for example if you use a custom domain with your Exponea setup.
    @available(*, deprecated)
    func configure(projectToken: String,
                   projectMapping: [EventType: [ExponeaProject]],
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
