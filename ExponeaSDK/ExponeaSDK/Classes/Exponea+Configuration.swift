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
        public let projectMapping: [EventType: [String]]?

        public init(
            projectToken: String,
            authorization: Authorization,
            baseUrl: String? = nil,
            projectMapping: [EventType: [String]]? = nil
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

        private init(
            enabled: Bool,
            appGroup: String? = nil,
            delegate: PushNotificationManagerDelegate? = nil,
            tokenTrackFrequency: TokenTrackFrequency = .onTokenChange
        ) {
            self.enabled = enabled
            self.appGroup = appGroup
            self.delegate = delegate
            self.tokenTrackFrequency = tokenTrackFrequency
        }

        public static func enabled(
            appGroup: String,
            delegate: PushNotificationManagerDelegate? = nil,
            tokenTrackFrequency: TokenTrackFrequency = .onTokenChange
        ) -> AutomaticPushNotificationTracking {
            return AutomaticPushNotificationTracking(
                enabled: true, appGroup: appGroup, delegate: delegate, tokenTrackFrequency: tokenTrackFrequency
            )
        }

        public static let disabled: AutomaticPushNotificationTracking = AutomaticPushNotificationTracking(enabled: false)
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

    func configure(
        _ projectSettings: ProjectSettings,
        automaticPushNotificationTracking: AutomaticPushNotificationTracking,
        automaticSessionTracking: AutomaticSessionTracking = .enabled(),
        defaultProperties: [String: JSONConvertible]? = nil,
        flushingSetup: FlushingSetup = FlushingSetup.default
    ) {
        do {
            let configuration = try Configuration(
                projectToken: projectSettings.projectToken,
                projectMapping: projectSettings.projectMapping,
                authorization: projectSettings.authorization,
                baseUrl: projectSettings.baseUrl,
                defaultProperties: defaultProperties,
                sessionTimeout: automaticSessionTracking.timeout,
                automaticSessionTracking: automaticSessionTracking.enabled,
                automaticPushNotificationTracking: automaticPushNotificationTracking.enabled,
                tokenTrackFrequency: automaticPushNotificationTracking.tokenTrackFrequency,
                appGroup: automaticPushNotificationTracking.appGroup,
                flushEventMaxRetries: flushingSetup.maxRetries
            )
            self.configuration = configuration
            pushNotificationsDelegate = automaticPushNotificationTracking.delegate
            flushingMode = flushingSetup.mode
        } catch {
            Exponea.logger.log(.error, message: "Can't create configuration: \(error.localizedDescription)")
        }
    }
}
