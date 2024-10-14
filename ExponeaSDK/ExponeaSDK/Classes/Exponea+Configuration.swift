//
//  Exonpea+Configuration.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 21/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

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
        manualSessionAutoClose: Bool = true
    ) {
        do {
            let configuration = try Configuration(
                projectToken: projectSettings.projectToken,
                projectMapping: projectSettings.projectMapping,
                authorization: projectSettings.authorization,
                baseUrl: projectSettings.baseUrl,
                defaultProperties: defaultProperties,
                inAppContentBlocksPlaceholders: inAppContentBlocksPlaceholders,
                sessionTimeout: automaticSessionTracking.timeout,
                automaticSessionTracking: automaticSessionTracking.enabled,
                automaticPushNotificationTracking: automaticPushNotificationTracking.enabled,
                requirePushAuthorization: automaticPushNotificationTracking.requirePushAuthorization,
                tokenTrackFrequency: automaticPushNotificationTracking.tokenTrackFrequency,
                appGroup: automaticPushNotificationTracking.appGroup,
                flushEventMaxRetries: flushingSetup.maxRetries,
                allowDefaultCustomerProperties: allowDefaultCustomerProperties ?? true,
                advancedAuthEnabled: advancedAuthEnabled,
                manualSessionAutoClose: manualSessionAutoClose
            )
            self.configuration = configuration
            pushNotificationsDelegate = automaticPushNotificationTracking.delegate
            flushingMode = flushingSetup.mode
            afterInit.setStatus(status: .configured)
        } catch {
            Exponea.logger.log(.error, message: "Can't create configuration: \(error.localizedDescription)")
        }
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
        manualSessionAutoClose: Bool = true
    ) {
        let taskBlock = { [weak self] in
            guard let self = self else { return }
            
            do {
                var willRunSelfCheck = false
                if self.isDebugModeEnabled {
                    willRunSelfCheck = self.checkPushSetup && pushNotificationTracking.isEnabled
                }

                let configuration = try Configuration(
                    projectToken: projectSettings.projectToken,
                    projectMapping: projectSettings.projectMapping,
                    authorization: projectSettings.authorization,
                    baseUrl: projectSettings.baseUrl,
                    defaultProperties: defaultProperties,
                    inAppContentBlocksPlaceholders: inAppContentBlocksPlaceholders,
                    sessionTimeout: automaticSessionTracking.timeout,
                    automaticSessionTracking: automaticSessionTracking.enabled,
                    automaticPushNotificationTracking: false,
                    requirePushAuthorization: pushNotificationTracking.requirePushAuthorization && !willRunSelfCheck,
                    tokenTrackFrequency: pushNotificationTracking.tokenTrackFrequency,
                    appGroup: pushNotificationTracking.appGroup,
                    flushEventMaxRetries: flushingSetup.maxRetries,
                    allowDefaultCustomerProperties: allowDefaultCustomerProperties ?? true,
                    advancedAuthEnabled: advancedAuthEnabled,
                    manualSessionAutoClose: manualSessionAutoClose
                )
                self.configure(with: configuration)
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
            } catch {
                Exponea.logger.log(.error, message: "Can't create configuration: \(error.localizedDescription)")
            }
        }

        if onInitSucceededCallBack != nil {
            initializedQueue.addOperation {
                taskBlock()
                onMain {
                    self.onInitSucceededCallBack?()
                }
            }
        } else {
            taskBlock()
        }
    }

    func setAutomaticSessionTracking(automaticSessionTracking: Exponea.AutomaticSessionTracking) {
        guard let repository = repository else {
            Exponea.logger.log(
                .warning, message: "Cannot set automaticSessionTracking before Exponea is configured."
            )
            return
        }
        repository.configuration.automaticSessionTracking = automaticSessionTracking.enabled
        repository.configuration.sessionTimeout = automaticSessionTracking.timeout
        trackingManager?.setAutomaticSessionTracking(automaticSessionTracking: automaticSessionTracking)
    }
}
