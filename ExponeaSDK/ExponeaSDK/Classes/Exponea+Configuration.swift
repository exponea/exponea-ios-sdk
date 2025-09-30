//
//  Exonpea+Configuration.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 21/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation
#if canImport(ExponeaSDKShared)
import ExponeaSDKShared
#endif

// MARK: - Configuration -

public extension Exponea {
    struct ProjectSettings {
        public let projectToken: String
        public let authorization: Authorization
        public let baseUrl: String
        public let projectMapping: [EventType: [ExponeaProject]]?

        public init(
            projectToken: String,
            authorization: Authorization,
            baseUrl: String? = nil,
            projectMapping: [EventType: [ExponeaProject]]? = nil
        ) {
            self.projectToken = projectToken
            self.authorization = authorization
            self.baseUrl = baseUrl ?? Constants.Repository.baseUrl
            self.projectMapping = projectMapping
        }
    }

    struct AutomaticPushNotificationTracking {
        let enabled: Bool
        let appGroup: String?
        weak var delegate: PushNotificationManagerDelegate?
        let tokenTrackFrequency: TokenTrackFrequency
        let requirePushAuthorization: Bool

        private init(
            enabled: Bool,
            appGroup: String? = nil,
            delegate: PushNotificationManagerDelegate? = nil,
            tokenTrackFrequency: TokenTrackFrequency = .onTokenChange,
            requirePushAuthorization: Bool = true
        ) {
            self.enabled = enabled
            self.appGroup = appGroup
            self.delegate = delegate
            self.tokenTrackFrequency = tokenTrackFrequency
            self.requirePushAuthorization = requirePushAuthorization
        }

        public static func enabled(
            appGroup: String,
            delegate: PushNotificationManagerDelegate? = nil,
            requirePushAuthorization: Bool = true,
            tokenTrackFrequency: TokenTrackFrequency = .onTokenChange
        ) -> AutomaticPushNotificationTracking {
            return AutomaticPushNotificationTracking(
                enabled: true,
                appGroup: appGroup,
                delegate: delegate,
                tokenTrackFrequency: tokenTrackFrequency,
                requirePushAuthorization: requirePushAuthorization
            )
        }

        public static let disabled = AutomaticPushNotificationTracking(enabled: false)
    }

    struct PushNotificationTracking {
        let isEnabled: Bool
        let appGroup: String?
        weak var delegate: PushNotificationManagerDelegate?
        let tokenTrackFrequency: TokenTrackFrequency
        let requirePushAuthorization: Bool

        private init(
            enabled: Bool,
            appGroup: String? = nil,
            delegate: PushNotificationManagerDelegate? = nil,
            tokenTrackFrequency: TokenTrackFrequency = .onTokenChange,
            requirePushAuthorization: Bool = true
        ) {
            self.isEnabled = enabled
            self.appGroup = appGroup
            self.delegate = delegate
            self.tokenTrackFrequency = tokenTrackFrequency
            self.requirePushAuthorization = requirePushAuthorization
        }

        public static func enabled(
            appGroup: String,
            delegate: PushNotificationManagerDelegate? = nil,
            requirePushAuthorization: Bool = true,
            tokenTrackFrequency: TokenTrackFrequency = .onTokenChange
        ) -> PushNotificationTracking {
            return PushNotificationTracking(
                enabled: true,
                appGroup: appGroup,
                delegate: delegate,
                tokenTrackFrequency: tokenTrackFrequency,
                requirePushAuthorization: requirePushAuthorization
            )
        }

        public static let disabled = PushNotificationTracking(enabled: false)
    }

    struct AutomaticSessionTracking {
        let enabled: Bool
        let timeout: Double

        private init(enabled: Bool, timeout: Double = Constants.Session.defaultTimeout) {
            self.enabled = enabled
            self.timeout = timeout
        }

        public static func enabled(timeout: Double = Constants.Session.defaultTimeout) -> AutomaticSessionTracking {
            return AutomaticSessionTracking(enabled: true, timeout: timeout)
        }

        public static let disabled: AutomaticSessionTracking = AutomaticSessionTracking(enabled: false)
    }

    struct FlushingSetup {
        let mode: FlushingMode
        let maxRetries: Int

        public static let `default` = FlushingSetup(mode: .immediate, maxRetries: Constants.Session.maxRetries)

        public init(mode: FlushingMode, maxRetries: Int = Constants.Session.maxRetries) {
            self.mode = mode
            self.maxRetries = maxRetries
        }
    }
}

public extension ExponeaInternal {
    var isConfigured: Bool {
        return (try? getDependenciesIfConfigured(.none)) != nil
    }
    private func invokeSdkInitSafely(
        _ initBlock: @escaping EmptyThrowsBlock
    ) {
        Exponea.logger.log(.verbose, message: "Request of SDK initialization registered")
        if onInitSucceededCallBack != nil {
            asyncSdkInitialisationQueue.addOperation {
                self.sdkInitialisationBlockQueue.sync {
                    guard !self.isConfigured else {
                        Exponea.logger.log(.error, message: "Exponea SDK already configured.")
                        return
                    }
                    do {
                        Exponea.logger.log(.verbose, message: "SDK init starts asynchronously")
                        try initBlock()
                        self.afterInit.setStatus(status: .configured)
                        Exponea.logger.log(.verbose, message: "SDK init ends asynchronously")
                        onMain {
                            self.onInitSucceededCallBack?()
                        }
                    } catch {
                        Exponea.logger.log(.error, message: "Can't create configuration: \(error.localizedDescription)")
                    }
                }
            }
            return
        }
        self.sdkInitialisationBlockQueue.sync {
            guard !self.isConfigured else {
                Exponea.logger.log(.error, message: "Exponea SDK already configured.")
                return
            }
            do {
                Exponea.logger.log(.verbose, message: "SDK init starts synchronously")
                try initBlock()
                self.afterInit.setStatus(status: .configured)
                Exponea.logger.log(.verbose, message: "SDK init ends synchronously")
            } catch {
                Exponea.logger.log(.error, message: "Can't create configuration: \(error.localizedDescription)")
            }
        }
    }

    // swiftlint:disable:next line_length
    @available(*, deprecated, message: "Automatic push notification tracking is deprecated. Find more information in the documentation. https://github.com/exponea/exponea-ios-sdk/blob/main/Documentation/PUSH.md")
    func configure(
        _ projectSettings: Exponea.ProjectSettings,
        automaticPushNotificationTracking: Exponea.AutomaticPushNotificationTracking,
        automaticSessionTracking: Exponea.AutomaticSessionTracking = .enabled(),
        defaultProperties: [String: JSONConvertible]? = nil,
        inAppContentBlocksPlaceholders: [String]? = nil,
        flushingSetup: Exponea.FlushingSetup = Exponea.FlushingSetup.default,
        allowDefaultCustomerProperties: Bool? = nil,
        advancedAuthEnabled: Bool? = nil,
        manualSessionAutoClose: Bool = true,
        applicationID: String? = nil
    ) {
        invokeSdkInitSafely({
            let configuration = try Configuration(
                projectToken: projectSettings.projectToken,
                projectMapping: projectSettings.projectMapping,
                authorization: projectSettings.authorization,
                baseUrl: projectSettings.baseUrl,
                appGroup: automaticPushNotificationTracking.appGroup,
                defaultProperties: defaultProperties,
                inAppContentBlocksPlaceholders: inAppContentBlocksPlaceholders,
                sessionTimeout: automaticSessionTracking.timeout,
                automaticSessionTracking: automaticSessionTracking.enabled,
                automaticPushNotificationTracking: automaticPushNotificationTracking.enabled,
                requirePushAuthorization: automaticPushNotificationTracking.requirePushAuthorization,
                tokenTrackFrequency: automaticPushNotificationTracking.tokenTrackFrequency,
                flushEventMaxRetries: flushingSetup.maxRetries,
                allowDefaultCustomerProperties: allowDefaultCustomerProperties ?? true,
                advancedAuthEnabled: advancedAuthEnabled,
                manualSessionAutoClose: manualSessionAutoClose,
                applicationID: applicationID
            )
            self.configuration = configuration
            self.pushNotificationsDelegate = automaticPushNotificationTracking.delegate
            self.flushingMode = flushingSetup.mode
        })
    }

    func configure(
        _ projectSettings: Exponea.ProjectSettings,
        pushNotificationTracking: Exponea.PushNotificationTracking,
        automaticSessionTracking: Exponea.AutomaticSessionTracking = .enabled(),
        defaultProperties: [String: JSONConvertible]? = nil,
        inAppContentBlocksPlaceholders: [String]? = nil,
        flushingSetup: Exponea.FlushingSetup = Exponea.FlushingSetup.default,
        allowDefaultCustomerProperties: Bool? = nil,
        advancedAuthEnabled: Bool? = nil,
        manualSessionAutoClose: Bool = true,
        applicationID: String? = nil
    ) {
        invokeSdkInitSafely {
            var willRunSelfCheck = false
            if self.isDebugModeEnabled {
                willRunSelfCheck = self.checkPushSetup && pushNotificationTracking.isEnabled
            }
            let configuration = try Configuration(
                projectToken: projectSettings.projectToken,
                projectMapping: projectSettings.projectMapping,
                authorization: projectSettings.authorization,
                baseUrl: projectSettings.baseUrl,
                appGroup: pushNotificationTracking.appGroup,
                defaultProperties: defaultProperties,
                inAppContentBlocksPlaceholders: inAppContentBlocksPlaceholders,
                sessionTimeout: automaticSessionTracking.timeout,
                automaticSessionTracking: automaticSessionTracking.enabled,
                automaticPushNotificationTracking: false,
                requirePushAuthorization: pushNotificationTracking.requirePushAuthorization && !willRunSelfCheck,
                tokenTrackFrequency: pushNotificationTracking.tokenTrackFrequency,
                flushEventMaxRetries: flushingSetup.maxRetries,
                allowDefaultCustomerProperties: allowDefaultCustomerProperties ?? true,
                advancedAuthEnabled: advancedAuthEnabled,
                manualSessionAutoClose: manualSessionAutoClose,
                applicationID: applicationID
            )
            self.configuration = configuration
            self.pushNotificationsDelegate = pushNotificationTracking.delegate
            self.flushingMode = flushingSetup.mode
            if willRunSelfCheck {
                self.executeSafelyWithDependencies { dependencies in
                    self.pushNotificationSelfCheck = PushNotificationSelfCheck(
                        trackingManager: dependencies.trackingManager,
                        flushingManager: dependencies.flushingManager,
                        repository: dependencies.repository,
                        notificationsManager: dependencies.notificationsManager
                    )
                    self.pushNotificationSelfCheck?.start()
                }
            }
        }
    }

    /// Initialize the configuration without a projectMapping (token mapping) for each type of event.
    ///
    /// - Parameters:
    ///   - projectToken: Project token to be used through the SDK.
    ///   - authorization: The authorization type used to authenticate with some Exponea endpoints.
    ///   - baseUrl: Base URL used for the project, for example if you use a custom domain with your Exponea setup.
    @available(*, deprecated)
    func configure(
        projectToken: String,
        authorization: Authorization,
        baseUrl: String? = nil,
        appGroup: String? = nil,
        defaultProperties: [String: JSONConvertible]? = nil,
        inAppContentBlocksPlaceholders: [String]? = nil,
        allowDefaultCustomerProperties: Bool? = nil,
        advancedAuthEnabled: Bool? = nil,
        manualSessionAutoClose: Bool = true,
        applicationID: String? = nil
    ) {
        invokeSdkInitSafely {
            let configuration = try Configuration(
                projectToken: projectToken,
                authorization: authorization,
                baseUrl: baseUrl,
                appGroup: appGroup,
                defaultProperties: defaultProperties,
                inAppContentBlocksPlaceholders: inAppContentBlocksPlaceholders,
                allowDefaultCustomerProperties: allowDefaultCustomerProperties ?? true,
                advancedAuthEnabled: advancedAuthEnabled,
                manualSessionAutoClose: manualSessionAutoClose,
                applicationID: applicationID
            )
            self.configuration = configuration
            self.afterInit.setStatus(status: .configured)
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
        invokeSdkInitSafely {
            let configuration = try Configuration(plistName: plistName)
            self.configuration = configuration
        }
    }

    func configure(with configuration: Configuration) {
        invokeSdkInitSafely {
            self.configuration = configuration
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
    func configure(
        projectToken: String,
        projectMapping: [EventType: [ExponeaProject]],
        authorization: Authorization,
        baseUrl: String? = nil,
        appGroup: String? = nil,
        defaultProperties: [String: JSONConvertible]? = nil,
        inAppContentBlocksPlaceholders: [String]? = nil,
        allowDefaultCustomerProperties: Bool? = nil,
        advancedAuthEnabled: Bool? = nil,
        manualSessionAutoClose: Bool = true,
        applicationID: String? = nil
    ) {
        invokeSdkInitSafely {
            let configuration = try Configuration(
                projectToken: projectToken,
                projectMapping: projectMapping,
                authorization: authorization,
                baseUrl: baseUrl,
                appGroup: appGroup,
                defaultProperties: defaultProperties,
                inAppContentBlocksPlaceholders: inAppContentBlocksPlaceholders,
                allowDefaultCustomerProperties: allowDefaultCustomerProperties ?? true,
                advancedAuthEnabled: advancedAuthEnabled,
                manualSessionAutoClose: manualSessionAutoClose,
                applicationID: applicationID
            )
            self.configuration = configuration
        }
    }

    func onInitSucceeded(callback completion: @escaping (() -> Void)) -> Self {
        if isConfigured {
            completion()
        } else {
            onInitSucceededCallBack = completion
        }
        return self
    }

    func setAutomaticSessionTracking(automaticSessionTracking: Exponea.AutomaticSessionTracking) {
        executeSafelyWithDependencies { dependencies in
            dependencies.repository.configuration.automaticSessionTracking = automaticSessionTracking.enabled
            dependencies.repository.configuration.sessionTimeout = automaticSessionTracking.timeout
            dependencies.trackingManager.setAutomaticSessionTracking(automaticSessionTracking: automaticSessionTracking)
        }
    }
}
