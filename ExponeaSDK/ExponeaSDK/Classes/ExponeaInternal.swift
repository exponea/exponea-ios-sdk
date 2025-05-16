//
//  ExponeaInternal.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 06/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
#if canImport(ExponeaSDKObjC)
import ExponeaSDKObjC
#endif
import UIKit

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
            sharedInitializer(configuration: newValue)
        }
    }

    // Non-nil callback hook activates async SDK init process.
    // Callback will be triggered on successful initialisation.
    internal var onInitSucceededCallBack: EmptyBlock?

    /// Cookie of the current customer. Nil before the SDK is configured
    public var customerCookie: String? {
        return trackingManager?.customerCookie
    }

    /// The manager responsible for tracking data and sessions.
    internal var trackingManager: TrackingManagerType?

    /// The manager wraps and applies GDPR consent for tracking data.
    internal var trackingConsentManager: TrackingConsentManagerType?

    /// The manager responsible for flushing data to Exponea servers.
    internal var flushingManager: FlushingManagerType?

    /// The manager responsible for preloading and showing in-app messages.
    internal var inAppMessagesManager: InAppMessagesManagerType?

    /// The manager responsible for handling appInbox messages.
    internal var appInboxManager: AppInboxManagerType?

    /// Repository responsible for fetching or uploading data to the API.
    internal var repository: RepositoryType?

    /// The manager for push registration and delivery tracking
    internal var notificationsManager: PushNotificationManagerType?

    internal var telemetryManager: TelemetryManager?

    internal var campaignRepository: CampaignRepositoryType?

    public var inAppContentBlocksManager: InAppContentBlocksManagerType?
    public var segmentationManager: SegmentationManagerType?
    public var manualSegmentationManager: ManualSegmentationManagerType?

    /// Custom user defaults to track basic information
    internal var userDefaults: UserDefaults = {
        if UserDefaults(suiteName: Constants.General.userDefaultsSuite) == nil {
            UserDefaults.standard.addSuite(named: Constants.General.userDefaultsSuite)
        }
        return UserDefaults(suiteName: Constants.General.userDefaultsSuite)!
    }()

    fileprivate func clearAllDependencies() {
        repository = nil
        trackingManager = nil
        flushingManager = nil
        trackingConsentManager = nil
        inAppMessagesManager = nil
        inAppContentBlocksManager = nil
        appInboxManager = nil
        notificationsManager = nil
        campaignRepository = nil
    }

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
            return notificationsManager?.delegate
        }
        set {
            guard let notificationsManager = notificationsManager else {
                Exponea.logger.log(
                    .warning,
                    message: "Cannot set push notifications delegate. " + Constants.ErrorMessages.sdkNotConfigured
                )
                return
            }
            notificationsManager.delegate = newValue
        }
    }

    /// The delegate that gets callbacks about in app message actions.
    public var inAppMessagesDelegate: InAppMessageActionDelegate = DefaultInAppDelegate()

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
            safeModeOverride ?? !isDebugModeEnabled
        }
        set { safeModeOverride = newValue }
    }
    private var safeModeOverride: Bool?

    public var isDebugModeEnabled: Bool {
        get {
            if let isDebugEnabledOverride {
                return isDebugEnabledOverride
            }
#if DEBUG
            return true
#else
            return false
#endif
        }
        set {
            isDebugEnabledOverride = newValue
        }
    }
    private var isDebugEnabledOverride: Bool?

    public var isDarkMode: Bool {
        guard configuration?.isDarkModeEnabled == true else { return false }
        if #available(iOS 12.0, *) {
            return UIScreen.main.traitCollection.userInterfaceStyle == .dark
        }
        return false
    }

    /// Once ExponeaSDK runs into a NSException, all further calls will be disabled
    internal var nsExceptionRaised: Bool = false
    fileprivate var databaeManagerCopy: DatabaseManager?

    internal var pushNotificationSelfCheck: PushNotificationSelfCheck?

    internal lazy var afterInit: ExpoInitManagerType = ExpoInitManager(sdk: self)
    /// To help developers with integration, we can automatically check push notification setup
    /// when application is started in debug mode.
    /// When integrating push notifications(or when testing), we
    /// advise you to turn this feature on before initializing the SDK.
    /// Self-check only runs in debug mode and does not do anything in release builds.
    public var checkPushSetup: Bool = false

    public var appInboxProvider: AppInboxProvider = DefaultAppInboxProvider()

    /// OperationQueue that is used upon SDK initialization
    /// This queue allows only 1 max concurrent operation
    internal lazy var asyncSdkInitialisationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .background
        queue.name = "com.exponea.ExponeaSDK.asyncInitQueue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    internal let sdkInitialisationBlockQueue = DispatchQueue(label: "com.exponea.ExponeaSDK.BlockInitQueue")

    internal lazy var inAppContentBlockStatusStore: InAppContentBlockDisplayStatusStore = {
        return InAppContentBlockDisplayStatusStore(userDefaults: userDefaults)
    }()

    internal var isAppForeground: Bool = false

    // MARK: - Init -

    /// The initialiser is internal, so that only the singleton can exist when used in production.
    internal init() {
        Exponea.logger.logMessage("⚙️ Starting ExponeaSDK, version \(Exponea.version).")
        registerApplicationStateListener()
    }

    deinit {
        if !Exponea.isBeingTested {
            Exponea.logger.log(.error, message: "Exponea has deallocated. This should never happen.")
        }
        unregisterApplicationStateListener()
    }

    internal func sharedInitializer(configuration: Configuration) {
        Exponea.logger.log(.verbose, message: "Configuring Exponea with provided configuration:\n\(configuration)")
        initialize(with: configuration)

    }

    /// Initialize all other dependencies
    /// This method, used privatly, is called either from the current thread (backwards compatibility)
    /// or when using the new onInitSucceededCallBack, it will be called wihtin the initializedQueue OperationQueue
    /// - Parameter configuration: Configuration
    private func initialize(with configuration: Configuration) {
        let exception = objc_tryCatch {
            do {
                IntegrationManager.shared.isStopped = false
                if let defaults = UserDefaults(suiteName: configuration.appGroup ?? Constants.General.userDefaultsSuite) {
                    defaults.set(false, forKey: "isStopped")
                }
                self.segmentationManager = SegmentationManager.shared
                self.manualSegmentationManager = ManualSegmentationManager.shared

                let database = try DatabaseManager()
                databaeManagerCopy = database
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
                        guard let inAppContentBlocksManager = self?.inAppContentBlocksManager else { return }
                        inAppContentBlocksManager.loadInAppContentBlockMessages {
                            if let placeholders = configuration.inAppContentBlocksPlaceholders {
                                inAppContentBlocksManager.prefetchPlaceholdersWithIds(ids: placeholders)
                            }
                        }
                    }
                )
                self.flushingManager = flushingManager

                let campaignRepository = CampaignRepository(
                    userDefaults: self.userDefaults
                )
                self.campaignRepository = campaignRepository

                let trackingManager = try TrackingManager(
                    repository: repository,
                    database: database,
                    flushingManager: flushingManager,
                    inAppMessageManager: inAppMessagesManager,
                    trackManagerInitializator: { trackingManager in
                        let trackingConsentManager = TrackingConsentManager(
                            trackingManager: trackingManager
                        )
                        self.trackingConsentManager = trackingConsentManager
                        let inAppMessagesManager = InAppMessagesManager(
                           repository: repository,
                           displayStatusStore: InAppMessageDisplayStatusStore(userDefaults: userDefaults),
                           trackingConsentManager: trackingConsentManager
                        )
                        self.inAppMessagesManager = inAppMessagesManager
                        let notificationsManager = PushNotificationManager(
                            trackingConsentManager: trackingConsentManager,
                            trackingManager: trackingManager,
                            swizzlingEnabled: repository.configuration.automaticPushNotificationTracking,
                            requirePushAuthorization: repository.configuration.requirePushAuthorization,
                            appGroup: repository.configuration.appGroup,
                            tokenTrackFrequency: repository.configuration.tokenTrackFrequency,
                            currentPushToken: database.currentCustomer.pushToken,
                            lastTokenTrackDate: database.currentCustomer.lastTokenTrackDate,
                            urlOpener: UrlOpener()
                        )
                        self.notificationsManager = notificationsManager
                    },
                    userDefaults: userDefaults,
                    campaignRepository: campaignRepository,
                    onEventCallback: { type, event in
                        self.inAppMessagesManager?.onEventOccurred(of: type, for: event, triggerCompletion: nil)
                        self.appInboxManager?.onEventOccurred(of: type, for: event)
                        if case .immediate = Exponea.shared.flushingMode {
                            self.segmentationManager?.processTriggeredBy(type: .identify)
                        }
                    }
                )

                self.trackingManager = trackingManager

                self.appInboxManager = AppInboxManager(
                    repository: repository,
                    trackingManager: trackingManager,
                    database: database
                )

                configuration.saveToUserDefaults()

                self.inAppContentBlocksManager = InAppContentBlocksManager.manager
                self.inAppContentBlocksManager?.initBlocker()
                self.inAppContentBlocksManager?.loadInAppContentBlockMessages { [weak self] in
                    self?.inAppContentBlocksManager?.prefetchPlaceholdersWithIds(ids: configuration.inAppContentBlocksPlaceholders ?? [])
                }

                if isDebugModeEnabled {
                    VersionChecker(repository: repository).warnIfNotLatestSDKVersion()
                }

                self.afterInit.doActionAfterExponeaInit {
                    SegmentationManager.shared.processTriggeredBy(type: .`init`)
                }
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
    struct Dependencies {
        let configuration: Configuration
        let repository: RepositoryType
        let trackingManager: TrackingManagerType
        let flushingManager: FlushingManagerType
        let trackingConsentManager: TrackingConsentManagerType
        let inAppMessagesManager: InAppMessagesManagerType
        let appInboxManager: AppInboxManagerType
        let inAppContentBlocksManager: InAppContentBlocksManagerType
        let notificationsManager: PushNotificationManagerType
        let campaignRepository: CampaignRepositoryType
    }

    typealias CompletionHandler<T> = ((Result<T>) -> Void)
    typealias DependencyTask<T> = (ExponeaInternal.Dependencies, @escaping CompletionHandler<T>) throws -> Void

    /// Gets the Exponea dependencies. If Exponea wasn't configured it will throw an error instead.
    ///
    /// - Returns: The dependencies required to perform any actions.
    /// - Throws: A not configured error in case Exponea wasn't configured beforehand.
    func getDependenciesIfConfigured(_ logLevel: LogLevel = .error) throws -> Dependencies {
        guard let configuration = configuration,
            let repository = repository,
            let trackingManager = trackingManager,
            let flushingManager = flushingManager,
            let trackingConsentManager = trackingConsentManager,
            let inAppMessagesManager = inAppMessagesManager,
            let inAppContentBlocksManager = inAppContentBlocksManager,
            let appInboxManager = appInboxManager,
            let notificationsManager = notificationsManager,
            let campaignRepository = campaignRepository else {
                Exponea.logger.log(logLevel, message: "Some dependencies are not configured")
                throw ExponeaError.notConfigured
        }
        return Dependencies(
            configuration: configuration,
            repository: repository,
            trackingManager: trackingManager,
            flushingManager: flushingManager,
            trackingConsentManager: trackingConsentManager,
            inAppMessagesManager: inAppMessagesManager,
            appInboxManager: appInboxManager,
            inAppContentBlocksManager: inAppContentBlocksManager,
            notificationsManager: notificationsManager,
            campaignRepository: campaignRepository
        )
    }

    func executeSafelyWithDependencies<T>(
        _ closure: @escaping DependencyTask<T>,
        completion: @escaping CompletionHandler<T>
    ) {
        executeSafely({
                let dependencies = try self.getDependenciesIfConfigured()
                try closure(dependencies, completion)
            },
            errorHandler: { error in completion(.failure(error)) }
        )
    }

    func executeSafelyWithDependencies(_ closure: @escaping (ExponeaInternal.Dependencies) throws -> Void) {
        executeSafelyWithDependencies({ dep, _ in try closure(dep) }, completion: { _ in } as CompletionHandler<Any>)
    }

    func executeSafely(_ closure: @escaping () throws -> Void) {
        executeSafely(closure, errorHandler: nil)
    }

    func executeSafely(_ closure: @escaping () throws -> Void, errorHandler: ((Error) -> Void)?) {
        logOnException({
            try self.afterInit.doActionAfterExponeaInit(closure)
        }, errorHandler: errorHandler)
    }

    func logOnException(_ closure: @escaping () throws -> Void, errorHandler: ((Error) -> Void)?) {
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

    func registerApplicationStateListener() {
        onMain {
            self.isAppForeground = UIApplication.shared.applicationState == .active
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    func unregisterApplicationStateListener() {
        self.isAppForeground = false
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    @objc func applicationDidBecomeActive() {
        self.isAppForeground = true
    }

    @objc func applicationDidEnterBackground() {
        self.isAppForeground = false
    }
}

// MARK: - Public -

public extension ExponeaInternal {
    @objc
    func openAppInboxList(sender: UIButton!) {
        onMain {
            let window = UIApplication.shared.keyWindow
            guard let topViewController = InAppMessagePresenter.getTopViewController(window: window) else {
                Exponea.logger.log(.error, message: "Unable to show AppInbox list - no view controller")
                return
            }
            let listView = Exponea.shared.appInboxProvider.getAppInboxListViewController()
            let naviController = UINavigationController(rootViewController: listView)
            naviController.modalPresentationStyle = .formSheet
            topViewController.present(naviController, animated: true)
        }
    }

    func getSegments(force: Bool = false, category: SegmentCategory, result: @escaping TypeBlock<[SegmentDTO]>) {
        executeSafelyWithDependencies { [weak self] _ in
            self?.manualSegmentationManager?.getSegments(category: category, force: force, result: result)
        }
    }

    func stopIntegration() {
        IntegrationManager.shared.isStopped = true
        afterInit.actionBlocks.removeAll()
        afterInit.setStatus(status: .notInitialized)
        afterInit.clean()
        clearUserData(appGroup: repository?.configuration.appGroup)
    }

    private func clearUserData(appGroup: String?) {
        IntegrationManager.shared.onIntegrationStoppedCallbacks.forEach { $0() }
        IntegrationManager.shared.onIntegrationStoppedCallbacks.removeAll()
        notificationsManager?.handlePushTokenRegistered(token: "")
        campaignRepository?.clear()
        databaeManagerCopy?.removeAllEvents()
        trackingManager?.clearSessionManager()
        InAppMessagesCache().clear()
        clearUserDefaults(appGroup: appGroup)
        clearAllDependencies()
    }

    func clearLocalCustomerData(appGroup: String) {
        guard !isConfigured && Configuration.loadFromUserDefaults(appGroup: appGroup) != nil else {
            Exponea.logger.log(.error, message: "This functionality is unavailable without initialization of SDK")
            return
        }
        IntegrationManager.shared.onIntegrationStoppedCallbacks.forEach { $0() }
        IntegrationManager.shared.onIntegrationStoppedCallbacks.removeAll()
        notificationsManager?.handlePushTokenRegistered(token: "")
        clearUserDefaults(appGroup: appGroup)
        InAppMessagesCache().clear()
        try? DatabaseManager().removeAllEvents()
        CampaignRepository(userDefaults: userDefaults).clear()
        clearAllDependencies()
    }

    private func clearUserDefaults(appGroup: String?) {
        if let appGroup, let defaults = UserDefaults(suiteName: appGroup) {
            for key in defaults.dictionaryRepresentation().keys where key != "isStopped" {
                defaults.removeObject(forKey: key)
            }
            defaults.removeObject(forKey: Constants.Keys.sessionEnded)
            defaults.removeObject(forKey: Constants.Keys.sessionStarted)
            defaults.removeObject(forKey: Constants.General.deliveredPushUserDefaultsKey)
            Configuration.deleteLastKnownConfig(appGroup: appGroup)
            defaults.synchronize()
        } else {
            if let defaults = UserDefaults(suiteName: Constants.General.userDefaultsSuite) {
                for key in defaults.dictionaryRepresentation().keys where key != "isStopped" {
                    defaults.removeObject(forKey: key)
                }
                defaults.removeObject(forKey: Constants.Keys.sessionEnded)
                defaults.removeObject(forKey: Constants.Keys.sessionStarted)
                defaults.removeObject(forKey: Constants.General.deliveredPushUserDefaultsKey)
                Configuration.deleteLastKnownConfig(appGroup: Constants.General.userDefaultsSuite)
                defaults.synchronize()
            }
        }
    }
}
