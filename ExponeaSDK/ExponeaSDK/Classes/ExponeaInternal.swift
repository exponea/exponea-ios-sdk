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
#if canImport(ExponeaSDKShared)
import ExponeaSDKShared
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
    
    /// The manager responsible for Stream JWT lifecycle.
    internal var jwtAuthManager: JwtAuthManager?

    /// Guards against concurrent `stopIntegration` calls.
    private var isStopping = false

    public var inAppContentBlocksManager: InAppContentBlocksManagerType?
    public var segmentationManager: SegmentationManagerType?
    public var manualSegmentationManager: ManualSegmentationManagerType?

    internal var userDefaults: UserDefaults = {
        if UserDefaults(suiteName: Constants.General.userDefaultsSuite) == nil {
            UserDefaults.standard.addSuite(named: Constants.General.userDefaultsSuite)
        }
        return UserDefaults(suiteName: Constants.General.userDefaultsSuite)!
    }()

    fileprivate func clearAllDependencies() {
        // Clear JWT from memory and keychain before tearing down
        jwtAuthManager?.clear()
        jwtAuthManager = nil
        JwtStreamAuthProvider.shared = nil
        if let repo = repository as? ServerRepository {
            repo.streamAuthProvider = nil
            repo.onAuthorizationError = nil
        }
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
    /// - Parameter appIdDidChange: Boolean value that describes if the application ID changed between instances
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
                        appGroup: configuration.appGroup,
                        userId: database.currentCustomer.uuid.uuidString
                    )
                    telemetryManager?.start()
                    telemetryManager?.report(initEventWithConfiguration: configuration)
                    let eventCount = try database.countTrackCustomer() + (try database.countTrackEvent())
                    telemetryManager?.report(
                        eventWithType: .eventCount,
                        properties: ["count": String(describing: eventCount)]
                    )
                    segmentationManager?.getCallbacks().forEach({ rtsCallback in
                        telemetryManager?.report(
                            eventWithType: .rtsCallbackRegistered, properties: [
                                "exposingCategory": rtsCallback.category.name
                            ]
                        )
                    })
                }

                let repository = ServerRepository(configuration: configuration)
                self.repository = repository
                
                // Set up JwtStreamAuthProvider and auth error handler by integration type
                switch configuration.integrationConfig.type {
                case .stream:
                    let jwtStore = KeychainJwtTokenStore()
                    jwtStore.clearToken()
                    let jwtManager = JwtAuthManager(
                        store: jwtStore,
                        isStreamIntegration: true
                    )
                    self.jwtAuthManager = jwtManager

                    let jwtProvider = JwtStreamAuthProvider(jwtAuthManager: jwtManager)
                    JwtStreamAuthProvider.shared = jwtProvider
                    repository.streamAuthProvider = jwtProvider

                    repository.onAuthorizationError = { [weak jwtManager] endpoint, statusCode, data in
                        let baseReason: JwtErrorContext.Reason = statusCode == 403 ? .notProvided : .invalid
                        let isExpired = (statusCode == 401) && Self.isTokenExpiredResponse(data: data)
                        let reason: JwtErrorContext.Reason = isExpired ? .expired : baseReason
                        jwtManager?.handleTokenError(
                            reason: reason,
                            endpoint: endpoint,
                            status: statusCode,
                            underlying: nil
                        )
                    }
                case .project:
                    self.jwtAuthManager = nil
                    repository.onAuthorizationError = nil
                }

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
                    inAppMessageManager: self.inAppMessagesManager,
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
                            urlOpener: UrlOpener(),
                            userDefaults: userDefaults,
                            currentApplicationID: repository.configuration.applicationID
                        )
                        self.notificationsManager = notificationsManager
                    },
                    userDefaults: userDefaults,
                    campaignRepository: campaignRepository,
                    requirePushAuthorization: repository.configuration.requirePushAuthorization,
                    onEventCallback: { type, event in
                        self.inAppMessagesManager?.onEventOccurred(of: type, for: event, triggerCompletion: nil)
                        self.appInboxManager?.onEventOccurred(of: type, for: event)
                        if case .immediate = Exponea.shared.flushingMode {
                            self.segmentationManager?.processTriggeredBy(type: .identify)
                        }
                    }
                )

                self.trackingManager = trackingManager
                self.jwtAuthManager?.setCustomerIdsProvider { [weak self] in self?.trackingManager?.customerIds }

                self.appInboxManager = AppInboxManager(
                    repository: repository,
                    trackingManager: trackingManager,
                    database: database,
                    cachedAppId: Configuration
                        .loadFromUserDefaults(appGroup: repository.configuration.appGroup ?? Constants.General.userDefaultsSuite)?.applicationID ?? Constants.General.applicationID
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
                telemetryManager?.report(
                    error: error,
                    stackTrace: Thread.callStackSymbols,
                    thread: TelemetryUtility.getCurrentThreadInfo()
                )
                // Failing gracefully, if setup failed
                Exponea.logger.log(.error, message: """
                    Error while creating dependencies, Exponea cannot be configured.\n\(error.localizedDescription)
                    """)
            }
        }
        if let exception = exception {
            nsExceptionRaised = true
            telemetryManager?.report(
                exception: exception,
                thread: TelemetryUtility.getCurrentThreadInfo()
            )
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
                telemetryManager?.report(
                    error: error,
                    stackTrace: Thread.callStackSymbols,
                    thread: TelemetryUtility.getCurrentThreadInfo()
                )
                errorHandler?(error)
            }
        }
        if let exception = exception {
            telemetryManager?.report(
                exception: exception,
                thread: TelemetryUtility.getCurrentThreadInfo()
            )
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
            Exponea.shared.telemetryManager?.report(
                eventWithType: .rtsGetSegments,
                properties: [
                    "exposingCategory": category.name,
                    "forceFetch": String(describing: force)
                ]
            )
            self?.manualSegmentationManager?.getSegments(category: category, force: force, result: result)
        }
    }

    func stopIntegration() {
        stopIntegration(completion: nil)
    }

    func stopIntegration(completion: (() -> Void)?) {
        guard !isStopping && !IntegrationManager.shared.isStopped else {
            Exponea.logger.log(.warning, message: "stopIntegration already in progress or completed — ignoring.")
            DispatchQueue.main.async { completion?() }
            return
        }
        isStopping = true

        Exponea.shared.telemetryManager?.report(eventWithType: .integrationStopped, properties: [:])

        let appGroup = repository?.configuration.appGroup

        let performTeardown: () -> Void = { [weak self] in
            IntegrationManager.shared.isStopped = true
            self?.afterInit.actionBlocks.removeAll()
            self?.afterInit.setStatus(status: .notInitialized)
            self?.afterInit.clean()
            self?.clearUserData(appGroup: appGroup)
            self?.isStopping = false
            DispatchQueue.main.async { completion?() }
        }

        guard let trackingManager = trackingManager,
              let flushingManager = flushingManager else {
            performTeardown()
            return
        }

        if repository?.configuration.automaticSessionTracking == true {
            try? trackingManager.track(.sessionEnd, with: [.timestamp(Date().timeIntervalSince1970)])
        }

        try? trackingManager.trackNotificationState(
            pushToken: trackingManager.customerPushToken,
            isValid: false,
            description: "Invalidated"
        )

        flushingManager.flushData(isFromIdentify: false) { _ in
            performTeardown()
        }
    }

    private func clearUserData(appGroup: String?) {
        // Clear JWT token when stopping integration (in-memory and Keychain)
        jwtAuthManager?.clear()
        clearJwtFromKeychain()
        
        TelemetryUtility.clearInstallIdFromAllStores(appGroup: appGroup)
        IntegrationManager.shared.onIntegrationStoppedCallbacks.forEach { $0() }
        IntegrationManager.shared.onIntegrationStoppedCallbacks.removeAll()
        notificationsManager?.handlePushTokenRegistered(token: "")
        campaignRepository?.clear()
        databaeManagerCopy?.removeAllEvents()
        trackingManager?.clearSessionManager()
        InAppMessagesCache().clear()
        clearUserDefaults(appGroup: appGroup)
        telemetryManager?.clear(appGroup)
        clearAllDependencies()
        FileCache.shared.clear()
    }

    func clearLocalCustomerData(appGroup: String) {
        guard !isConfigured && Configuration.loadFromUserDefaults(appGroup: appGroup) != nil else {
            Exponea.logger.log(.error, message: "This functionality is unavailable without initialization of SDK")
            return
        }
        TelemetryUtility.clearInstallIdFromAllStores(appGroup: appGroup)
        Exponea.shared.telemetryManager?.report(
            eventWithType: .localCustomerDataCleared,
            properties: [
                "appGroup": appGroup
            ]
        )
        IntegrationManager.shared.onIntegrationStoppedCallbacks.forEach { $0() }
        IntegrationManager.shared.onIntegrationStoppedCallbacks.removeAll()
        notificationsManager?.handlePushTokenRegistered(token: "")
        clearUserDefaults(appGroup: appGroup)
        telemetryManager?.clear(appGroup)
        InAppMessagesCache().clear()
        try? DatabaseManager().removeAllEvents()
        CampaignRepository(userDefaults: userDefaults).clear()
        
        // Clear JWT from Keychain - need to do this directly since jwtAuthManager may be nil
        clearJwtFromKeychain()
        
        clearAllDependencies()
        FileCache.shared.clear()
    }
    
    /// Clears JWT token from Keychain. Used when SDK is not initialized but we need to clear local data.
    private func clearJwtFromKeychain() {
        let store = KeychainJwtTokenStore()
        store.clearToken()
        Exponea.logger.log(.verbose, message: "JWT token cleared from Keychain during local data cleanup")
    }

    /// Returns true when the Tracking API response body contains token_expired: true (JWT no longer valid).
    private static func isTokenExpiredResponse(data: Data?) -> Bool {
        guard let data = data,
              let any = try? JSONSerialization.jsonObject(with: data),
              let json = any as? [String: Any],
              let flag = json["token_expired"] as? Bool else { return false }
        return flag
    }

    /// Clears SDK-related keys from UserDefaults (session, config, etc.).
    /// Install ID is cleared by clearInstallIdFromAllStores, which callers invoke before this.
    /// We also clear known SDK keys from UserDefaults.standard so that if the SDK ever used
    /// standard as fallback (named suite was nil), no stale SDK data remains. We never clear
    /// all of standard—only these keys—so app and other SDKs are unaffected.
    private func clearUserDefaults(appGroup: String?) {
        if let appGroup, let defaults = UserDefaults(suiteName: appGroup) {
            for key in defaults.dictionaryRepresentation().keys where key != "isStopped" {
                defaults.removeObject(forKey: key)
            }
            defaults.removeObject(forKey: Constants.Keys.sessionEnded)
            defaults.removeObject(forKey: Constants.Keys.sessionStarted)
            defaults.removeObject(forKey: Constants.General.deliveredPushUserDefaultsKey)
            defaults.removeObject(forKey: Constants.General.telemetryInstallId)
            defaults.removeObject(forKey: Constants.General.notificationStateTracked)
            defaults.removeObject(forKey: Constants.General.notificationStateAppVersion)
            defaults.removeObject(forKey: Constants.General.notificationStateApplicationID)
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
                defaults.removeObject(forKey: Constants.General.telemetryInstallId)
                defaults.removeObject(forKey: Constants.General.notificationStateTracked)
                defaults.removeObject(forKey: Constants.General.notificationStateAppVersion)
                defaults.removeObject(forKey: Constants.General.notificationStateApplicationID)
                Configuration.deleteLastKnownConfig(appGroup: Constants.General.userDefaultsSuite)
                defaults.synchronize()
            }
        }
        clearKnownSDKKeysFromStandard()
    }

    /// Removes only known Exponea SDK keys from UserDefaults.standard. Used when the canonical
    /// store may have been standard (e.g. suite was nil). Does not clear other app data.
    private func clearKnownSDKKeysFromStandard() {
        let standard = UserDefaults.standard
        standard.removeObject(forKey: Constants.General.telemetryInstallId)
        standard.removeObject(forKey: Constants.Keys.sessionEnded)
        standard.removeObject(forKey: Constants.Keys.sessionStarted)
        standard.removeObject(forKey: Constants.General.deliveredPushUserDefaultsKey)
        standard.removeObject(forKey: Constants.General.deliveredPushEventUserDefaultsKey)
        standard.removeObject(forKey: Constants.General.openedPushUserDefaultsKey)
        standard.removeObject(forKey: Constants.General.lastKnownConfiguration)
        standard.removeObject(forKey: Constants.General.lastKnownCustomerIds)
        standard.removeObject(forKey: Constants.General.savedCampaignClickEvent)
        standard.removeObject(forKey: Constants.General.inAppMessageDisplayStatusUserDefaultsKey)
        standard.removeObject(forKey: Constants.General.inAppContentBlockDisplayStatusUserDefaultsKey)
        standard.removeObject(forKey: Constants.General.notificationStateApplicationID)
        standard.removeObject(forKey: Constants.General.telemetryEvents)
        standard.removeObject(forKey: Constants.General.notificationStateTracked)
        standard.removeObject(forKey: Constants.General.notificationStateAppVersion)
        for key in standard.dictionaryRepresentation().keys where key.hasPrefix(Constants.Keys.installTracked) {
            standard.removeObject(forKey: key)
        }
        standard.synchronize()
    }
}
