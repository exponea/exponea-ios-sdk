//
//  Configuration.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 06/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import CoreData

/// A configuration object used to configure Exponea when initialising.
public struct Configuration: Codable, Equatable {
    @available(*, deprecated, message: "Please use exponeaIntegrationMapping in integrationConfig instead.")
    public internal(set) var projectMapping: [EventType: [ExponeaProject]]? {
        didSet {
            if let projectSettings = integrationConfig as? Exponea.ProjectSettings {
                integrationConfig = Exponea.ProjectSettings(
                    projectToken: projectSettings.projectToken,
                    authorization: projectSettings.authorization,
                    baseUrl: projectSettings.baseUrl,
                    projectMapping: projectMapping
                )
            }
        }
    }
    
    @available(*, deprecated, message: "Please use projectToken in integrationConfig instead.")
    public internal(set) var projectToken: String = "" {
        didSet {
            if let projectSettings = integrationConfig as? Exponea.ProjectSettings {
                integrationConfig = Exponea.ProjectSettings(
                    projectToken: projectToken,
                    authorization: projectSettings.authorization,
                    baseUrl: projectSettings.baseUrl,
                    projectMapping: projectSettings.projectMapping
                )
            }
        }
    }
    
    @available(*, deprecated, message: "Please use authorization in integrationConfig instead.")
    public internal(set) var authorization: Authorization = Authorization.none {
        didSet {
            if let projectSettings = integrationConfig as? Exponea.ProjectSettings {
                integrationConfig = Exponea.ProjectSettings(
                    projectToken: projectSettings.projectToken,
                    authorization: authorization,
                    baseUrl: projectSettings.baseUrl,
                    projectMapping: projectSettings.projectMapping
                )
            }
        }
    }
    
    @available(*, deprecated, message: "Please use baseUrl in integrationConfig instead.")
    public internal(set) var baseUrl: String = Constants.Repository.baseUrl {
        didSet {
            if let projectSettings = integrationConfig as? Exponea.ProjectSettings {
                integrationConfig = Exponea.ProjectSettings(
                    projectToken: projectSettings.projectToken,
                    authorization: projectSettings.authorization,
                    baseUrl: baseUrl,
                    projectMapping: projectSettings.projectMapping
                )
            }
        }
    }
    
    public var integrationId: String {
        integrationConfig.type.integrationId
    }
    
    public var inAppContentBlocksPlaceholders: [String]?
    public var defaultProperties: [String: JSONConvertible]?
    public var sessionTimeout: Double = Constants.Session.defaultTimeout
    public var automaticSessionTracking: Bool = true
    public var applicationID: String = Constants.General.applicationID
    public internal(set) var integrationConfig: any IntegrationType

    /// If enabled, will swizzle default push notifications methods and functions and automatically
    /// listen to updates for tokens or push settings.
    public internal(set) var automaticPushNotificationTracking: Bool = true

    /// If true, push notification registration and push token tracking is only done if the device is authorized
    /// to receive push notifications.
    /// Disabling is useful for silent push notifications that don't require authorization.
    /// In that case, registration and token tracking is done at app start automatically.
    public internal(set) var requirePushAuthorization: Bool = true

    /// If automatic push notification tracking is enabled, this can be used to determine how often
    /// should the push notification token be sent to Exponea.
    public internal(set) var tokenTrackFrequency: TokenTrackFrequency = .onTokenChange

    /// App group is used when push notification data is shared among service or content extensions.
    /// This is required for tracking delivered push notifications properly.
    public internal(set) var appGroup: String?

    /// The maximum amount of retries before a flush event is considered as invalid and deleted from the database.
    public internal(set) var flushEventMaxRetries: Int = Constants.Session.maxRetries

    /// If true, default properties are applied also for 'identifyCustomer' event.
    public internal(set) var allowDefaultCustomerProperties: Bool = true

    /// If true, advanced authorization is used for communication with BE
    public var advancedAuthEnabled: Bool = false

    /// Advanced authorization provider instance
    public internal(set) var customAuthProvider: AuthorizationProviderType?
    
    /// Is dark mode enabled
    public internal(set) var isDarkModeEnabled: Bool?

    ///  App inbox detail image inset
    public internal(set) var appInboxDetailImageInset: CGFloat?

    ///  Manual session autoclose
    public internal(set) var manualSessionAutoClose: Bool = true

    enum CodingKeys: String, CodingKey {
        case projectMapping
        case projectToken
        case authorization
        case baseUrl
        case defaultProperties
        case sessionTimeout
        case automaticSessionTracking
        case automaticPushNotificationTracking
        case requirePushAuthorization
        case tokenTrackFrequency
        case appGroup
        case flushEventMaxRetries
        case allowDefaultCustomerProperties
        case advancedAuthEnabled
        case isDarkModeEnabled
        case appInboxDetailImageInset
        case applicationID
        case streamId
    }

    /// Creates the configuration object with the provided properties.
    @available(*, deprecated, message: "Please use init with 'integrationConfig: any IntegrationType' parameter instead.")
    public init(
        projectToken: String,
        projectMapping: [EventType: [ExponeaProject]]? = nil,
        authorization: Authorization? = nil,
        baseUrl: String? = nil,
        appGroup: String? = nil,
        defaultProperties: [String: JSONConvertible]? = nil,
        inAppContentBlocksPlaceholders: [String]? = nil,
        sessionTimeout: Double? = nil,
        automaticSessionTracking: Bool? = nil,
        automaticPushNotificationTracking: Bool? = nil,
        requirePushAuthorization: Bool? = nil,
        tokenTrackFrequency: TokenTrackFrequency? = nil,
        flushEventMaxRetries: Int? = nil,
        allowDefaultCustomerProperties: Bool? = nil,
        advancedAuthEnabled: Bool? = nil,
        isDarkModeEnabled: Bool? = nil,
        appInboxDetailImageInset: CGFloat? = nil,
        manualSessionAutoClose: Bool? = nil,
        applicationID: String? = nil
    ) throws {
        self.projectToken = projectToken
        self.projectMapping = projectMapping
        self.authorization = authorization ?? Authorization.none
        self.appGroup = appGroup
        self.defaultProperties = defaultProperties
        self.allowDefaultCustomerProperties = allowDefaultCustomerProperties ?? true
        self.advancedAuthEnabled = advancedAuthEnabled ?? false
        self.inAppContentBlocksPlaceholders = inAppContentBlocksPlaceholders
        self.appInboxDetailImageInset = appInboxDetailImageInset ?? 56
        self.manualSessionAutoClose = manualSessionAutoClose ?? true
        if let applicationID, !applicationID.isEmpty {
            self.applicationID = applicationID
        }
        self.baseUrl = baseUrl ?? Constants.Repository.baseUrl
        
        self.integrationConfig = Exponea.ProjectSettings(
            projectToken: self.projectToken,
            authorization: self.authorization,
            baseUrl: self.baseUrl,
            projectMapping: self.projectMapping
        )
        
        if self.advancedAuthEnabled {
            self.customAuthProvider = try loadCustomAuthProvider()
        }
        self.isDarkModeEnabled = isDarkModeEnabled ?? false
        self.sessionTimeout = sessionTimeout ?? Constants.Session.defaultTimeout
        self.automaticSessionTracking = automaticSessionTracking ?? true
        self.automaticPushNotificationTracking = automaticPushNotificationTracking ?? true
        self.requirePushAuthorization = requirePushAuthorization ?? true
        self.tokenTrackFrequency = tokenTrackFrequency ?? .onTokenChange
        self.flushEventMaxRetries = flushEventMaxRetries ?? Constants.Session.maxRetries
        
        try self.validate()
    }
    
    public init(
        integrationConfig: any IntegrationType,
        appGroup: String? = nil,
        defaultProperties: [String: JSONConvertible]? = nil,
        inAppContentBlocksPlaceholders: [String]? = nil,
        sessionTimeout: Double? = nil,
        automaticSessionTracking: Bool? = nil,
        automaticPushNotificationTracking: Bool? = nil,
        requirePushAuthorization: Bool? = nil,
        tokenTrackFrequency: TokenTrackFrequency? = nil,
        flushEventMaxRetries: Int? = nil,
        allowDefaultCustomerProperties: Bool? = nil,
        advancedAuthEnabled: Bool? = nil,
        isDarkModeEnabled: Bool? = nil,
        appInboxDetailImageInset: CGFloat? = nil,
        manualSessionAutoClose: Bool? = nil,
        applicationID: String? = nil
    ) throws {
        self.integrationConfig = integrationConfig
        self.appGroup = appGroup
        self.defaultProperties = defaultProperties
        self.allowDefaultCustomerProperties = allowDefaultCustomerProperties ?? true
        self.advancedAuthEnabled = advancedAuthEnabled ?? false
        self.inAppContentBlocksPlaceholders = inAppContentBlocksPlaceholders
        self.appInboxDetailImageInset = appInboxDetailImageInset ?? 56
        self.manualSessionAutoClose = manualSessionAutoClose ?? true
        if let applicationID, !applicationID.isEmpty {
            self.applicationID = applicationID
        }
        // Only load customAuthProvider for Project mode - Stream uses JWT instead
        if case .project = integrationConfig.type, self.advancedAuthEnabled {
            self.customAuthProvider = try loadCustomAuthProvider()
        }
        self.isDarkModeEnabled = isDarkModeEnabled ?? false
        self.sessionTimeout = sessionTimeout ?? Constants.Session.defaultTimeout
        self.automaticSessionTracking = automaticSessionTracking ?? true
        self.automaticPushNotificationTracking = automaticPushNotificationTracking ?? true
        self.requirePushAuthorization = requirePushAuthorization ?? true
        self.tokenTrackFrequency = tokenTrackFrequency ?? .onTokenChange
        self.flushEventMaxRetries = flushEventMaxRetries ?? Constants.Session.maxRetries
        try self.validate()
    }

    /// Creates the Configuration object from a plist file.
    ///
    /// - Parameter plistName: The name of the plist file you want to load configuration from.
    public init(plistName: String) throws {
        for bundle in Bundle.allBundles {
            let fileName = plistName.replacingOccurrences(of: ".plist", with: "")
            guard let fileURL = bundle.url(forResource: fileName, withExtension: "plist") else {
                continue
            }

            Exponea.logger.log(.verbose, message: """
                Found configuration file with name \(fileName) in bundle: \(bundle.bundlePath)
                """)

            // Load the data
            let data = try Data(contentsOf: fileURL)

            // Decode from plist
            self = try PropertyListDecoder().decode(Configuration.self, from: data)
            // Only load customAuthProvider for Project mode - Stream uses JWT instead
            if case .project = self.integrationConfig.type, self.advancedAuthEnabled {
                self.customAuthProvider = try loadCustomAuthProvider()
            }
            try self.validate()

            // Stop if we found the file and decoded successfully
            return
        }
        throw ExponeaError.configurationError("Configuration plist not found.")
    }

    // MARK: - Decodable -

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        var streamId = ""
        
        if let streamIdToken = try container.decodeIfPresent(String.self, forKey: .streamId) {
            streamId = streamIdToken
        }
        
        // Base URL
        if let baseUrl = try container.decodeIfPresent(String.self, forKey: .baseUrl) {
            self.baseUrl = baseUrl
        }

        // Authorization
        if let authorization = try container.decodeIfPresent(Authorization.self, forKey: .authorization) {
            self.authorization = authorization
        }
        
        if streamId.isEmpty {
            guard let projectTokenValue = try container.decodeIfPresent(String.self, forKey: .projectToken) else {
                throw ExponeaError.configurationError("No project token or stream ID provided.")
            }
                    
            self.projectToken = projectTokenValue

            // Project token mapping
            if let dictionary = try container.decodeIfPresent(Dictionary<String, [ExponeaProject]>.self, forKey: .projectMapping) {
                var mapping: [EventType: [ExponeaProject]] = [:]
                for (_, element: (key: event, value: projectArray)) in dictionary.enumerated() {
                    guard let eventType = EventType(rawValue: event) else { continue }
                    mapping[eventType] = projectArray
                }
                self.projectMapping = mapping
            }
            
            integrationConfig = Exponea.ProjectSettings(
                projectToken: projectTokenValue,
                authorization: self.authorization,
                baseUrl: self.baseUrl,
                projectMapping: self.projectMapping
            )
        } else {
            integrationConfig = Exponea.StreamSettings(
                streamId: streamId,
                baseUrl: self.baseUrl
            )
        }
        
        // Session timeout
        if let sessionTimeout = try container.decodeIfPresent(Double.self, forKey: .sessionTimeout) {
            self.sessionTimeout = sessionTimeout
        }

        // Automatic sessiont racking
        if let automaticSessionTracking = try container.decodeIfPresent(
            Bool.self, forKey: .automaticSessionTracking) {
            self.automaticSessionTracking = automaticSessionTracking
        }

        // Automatic push notifications
        if let automaticPushNotificationTracking = try container.decodeIfPresent(
            Bool.self, forKey: .automaticPushNotificationTracking) {
            self.automaticPushNotificationTracking = automaticPushNotificationTracking
        }

        // Requiring push authorization
        if let requirePushAuthorization = try container.decodeIfPresent(
            Bool.self, forKey: .requirePushAuthorization) {
            self.requirePushAuthorization = requirePushAuthorization
        }

        // Token track frequency
        if let tokenTrackFrequency = try container.decodeIfPresent(
            TokenTrackFrequency.self, forKey: .tokenTrackFrequency) {
            self.tokenTrackFrequency = tokenTrackFrequency
        }

        // Flush event max retries
        if let flushEventMaxRetries = try container.decodeIfPresent(
            Int.self, forKey: .flushEventMaxRetries) {
            self.flushEventMaxRetries = flushEventMaxRetries
        }
        
        // application ID setting
        if let applicationID = try container.decodeIfPresent(String.self, forKey: .applicationID) {
            self.applicationID = applicationID
        }

        // isDarkModeEnabled
        if let isDarkModeEnabled = try container.decodeIfPresent(
            Bool.self, forKey: .isDarkModeEnabled) {
            self.isDarkModeEnabled = isDarkModeEnabled
        }
    
        // appInboxDetailImageInset
        if let appInboxDetailImageInset = try container.decodeIfPresent(
            CGFloat.self, forKey: .appInboxDetailImageInset) {
            self.appInboxDetailImageInset = appInboxDetailImageInset
        }

        // App group
        if let appGroup = try container.decodeIfPresent(String.self, forKey: .appGroup) {
            self.appGroup = appGroup
        }

        // Default properties
        if let defaultDictionary = try container.decodeIfPresent(
            [String: JSONValue].self, forKey: .defaultProperties) {
            var properties: [String: JSONConvertible] = [:]
            defaultDictionary.forEach({ property in
                properties[property.key] = property.value.jsonConvertible
            })
            guard !properties.isEmpty else { return }
            self.defaultProperties = properties
        }

        // Default properties usage for Identify Customer event
        if let allowDefaultCustomerProperties = try container.decodeIfPresent(
            Bool.self, forKey: .allowDefaultCustomerProperties) {
            self.allowDefaultCustomerProperties = allowDefaultCustomerProperties
        } else {
            self.allowDefaultCustomerProperties = true
        }

        // Advanced auth token
        if let advancedAuthEnabled = try container.decodeIfPresent(
            Bool.self, forKey: .advancedAuthEnabled) {
            self.advancedAuthEnabled = advancedAuthEnabled
        } else {
            self.advancedAuthEnabled = false
        }

        // Advanced auth provider - only for Project mode (Stream uses JWT instead)
        if case .project = self.integrationConfig.type, self.advancedAuthEnabled {
            self.customAuthProvider = try loadCustomAuthProvider()
        }
        try self.validate()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch integrationConfig.type {
        case .project(let projectToken):
            if let mapping = (integrationConfig as? Exponea.ProjectSettings)?.projectMapping {
                let projectMappingWithStringKeys = Dictionary(
                    uniqueKeysWithValues: mapping.map { (key: EventType, value: [ExponeaProject]) in (key.rawValue, value) }
                )
                try container.encode(projectMappingWithStringKeys, forKey: .projectMapping)
            }
            try container.encode((integrationConfig as? Exponea.ProjectSettings)?.authorization, forKey: .authorization)
            try container.encode(projectToken, forKey: .projectToken)
        case .stream(let streamId):
            try container.encode(streamId, forKey: .streamId)
        }
        try container.encode(integrationConfig.baseUrl, forKey: .baseUrl)
        
        try container.encode(defaultProperties?.mapValues { $0.jsonValue }, forKey: .defaultProperties)
        try container.encode(sessionTimeout, forKey: .sessionTimeout)
        try container.encode(automaticSessionTracking, forKey: .automaticSessionTracking)
        try container.encode(automaticPushNotificationTracking, forKey: .automaticPushNotificationTracking)
        try container.encode(requirePushAuthorization, forKey: .requirePushAuthorization)
        try container.encode(tokenTrackFrequency, forKey: .tokenTrackFrequency)
        try container.encode(appGroup, forKey: .appGroup)
        try container.encode(flushEventMaxRetries, forKey: .flushEventMaxRetries)
        try container.encode(allowDefaultCustomerProperties, forKey: .allowDefaultCustomerProperties)
        try container.encode(advancedAuthEnabled, forKey: .advancedAuthEnabled)
        try container.encode(applicationID, forKey: .applicationID)
    }

    public static func == (lhs: Configuration, rhs: Configuration) -> Bool {
        if let lhsProjectSettings = lhs.integrationConfig as? Exponea.ProjectSettings, let rhsProjectSettings = rhs.integrationConfig as? Exponea.ProjectSettings {
            return
                lhsProjectSettings == rhsProjectSettings &&
                areValuesInConfigurationsEqual(lhs: lhs, rhs: rhs)
                
        } else if let lhsStreamSettings = lhs.integrationConfig as? Exponea.StreamSettings, let rhsStreamSettings = rhs.integrationConfig as? Exponea.StreamSettings {
            return
                lhsStreamSettings == rhsStreamSettings &&
                areValuesInConfigurationsEqual(lhs: lhs, rhs: rhs)
        } else {
            return
                lhs.projectMapping == rhs.projectMapping &&
                lhs.projectToken == rhs.projectToken &&
                lhs.authorization == rhs.authorization &&
                lhs.baseUrl == rhs.baseUrl &&
                areValuesInConfigurationsEqual(lhs: lhs, rhs: rhs)
        }
    }
    
    private static func areValuesInConfigurationsEqual(lhs: Configuration, rhs: Configuration) -> Bool {
        return
            lhs.defaultProperties?.mapValues { $0.jsonValue } == rhs.defaultProperties?.mapValues { $0.jsonValue } &&
            lhs.sessionTimeout == rhs.sessionTimeout &&
            lhs.automaticSessionTracking == rhs.automaticSessionTracking &&
            lhs.automaticPushNotificationTracking == rhs.automaticPushNotificationTracking &&
            lhs.requirePushAuthorization == rhs.requirePushAuthorization &&
            lhs.tokenTrackFrequency == rhs.tokenTrackFrequency &&
            lhs.appGroup == rhs.appGroup &&
            lhs.flushEventMaxRetries == rhs.flushEventMaxRetries &&
            lhs.allowDefaultCustomerProperties == rhs.allowDefaultCustomerProperties &&
            lhs.advancedAuthEnabled == rhs.advancedAuthEnabled &&
            lhs.applicationID == rhs.applicationID
    }
}

extension Configuration {
    public func projects(for eventType: EventType) -> [any ExponeaIntegrationType] {
        var projects: [any ExponeaIntegrationType] = [mainProject]
        
        if let mapping = (integrationConfig as? Exponea.ProjectSettings)?.projectMapping,
           let mappedTokens = mapping[eventType] {
            projects.append(contentsOf: mappedTokens)
        }

        return projects
    }

    public var mainProject: any ExponeaIntegrationType {
        switch integrationConfig.type {
        case .project(let projectToken):
            return ExponeaProject(
                baseUrl: integrationConfig.baseUrl,
                projectToken: projectToken,
                authorization: (integrationConfig as? Exponea.ProjectSettings)?.authorization ?? Authorization.none
            )
        case .stream(let streamId):
            return ExponeaIntegration(
                baseUrl: integrationConfig.baseUrl,
                streamId: streamId
            )
        }
    }

    /// Returns the integration type enriched with advanced auth when available (Project mode only).
    /// Stream JWT is NOT embedded here — it is injected at the HTTP-request level by RequestFactory
    /// via the `streamAuthProvider` on ServerRepository.
    /// !!! Access it in background thread due to possibility of fetching of Customer Token value
    public var mutualExponeaProject: any ExponeaIntegrationType {
        switch integrationConfig.type {
        case .stream:
            return mainProject
        case .project(let projectToken):
            guard let provider = customAuthProvider else {
                return mainProject
            }
            let authToken = provider.getAuthorizationToken()
            let authorization: Authorization
            if let authToken = authToken, !authToken.isEmpty {
                authorization = .bearer(token: authToken)
            } else {
                authorization = Authorization.none
            }
            return ExponeaProject(
                baseUrl: integrationConfig.baseUrl,
                projectToken: projectToken,
                authorization: authorization
            )
        }
    }

    private func loadCustomAuthProvider() throws -> AuthorizationProviderType? {
        let className = "ExponeaAuthProvider"
        guard let foundClass = NSClassFromString(className) else {
            // valid exit
            return nil
        }
        guard let asNSObjectClass = foundClass as? NSObject.Type else {
            Exponea.logger.log(.error, message: "Class '\(className)' does not conform to NSObject")
            throw ConfigurationValidationError.advancedAuthInvalid(
                "Class '\(className)' does not conform to NSObject"
            )
        }
        guard let asProviderClass = asNSObjectClass as? AuthorizationProviderType.Type else {
            Exponea.logger.log(.error, message: "Class '\(className)' does not conform to AuthorizationProviderType")
            throw ConfigurationValidationError.advancedAuthInvalid(
                "Class '\(className)' does not conform to AuthorizationProviderType"
            )
        }
        return asProviderClass.init()
    }
}

extension Configuration: CustomStringConvertible {
    public var description: String {
        var text = "[Configuration]\n"

        switch integrationConfig.type {
        case .project(let projectToken):
            if let mapping = (integrationConfig as? Exponea.ProjectSettings)?.projectMapping {
                text += "Project Token Mapping: \(mapping)\n"
            }
            text += "Authorization: \((integrationConfig as? Exponea.ProjectSettings)?.authorization ?? Authorization.none)"

            text += "Project Token: \(projectToken)\n"
        case .stream(let streamId):
            text += "Stream ID Token: \(streamId)\n"
        }
        
        if let defaultProperties = defaultProperties {
            text += "Default Attributes: \(defaultProperties)\n"
        }

        text += """
        Base URL: \(integrationConfig.baseUrl)
        Session Timeout: \(sessionTimeout)
        Automatic Session Tracking: \(automaticSessionTracking)
        Automatic Push Notification Tracking: \(automaticPushNotificationTracking)
        Require Push Authorization: \(requirePushAuthorization)
        Token Track Frequency: \(tokenTrackFrequency)
        Flush Event Max Retries: \(flushEventMaxRetries)
        App Group: \(appGroup ?? "not configured")
        Default Customer Props allowed: \(allowDefaultCustomerProperties)
        Advanced authorization Enabled: \(advancedAuthEnabled)
        Application ID: \(applicationID)
        """

        return text
    }

    /// Returns the hostname based on the baseUrl value.
    public var hostname: String {
        guard let components = URLComponents(string: integrationConfig.baseUrl),
            let host = components.host else {
            Exponea.logger.log(.warning, message: "Can't get URL components from baseUrl, check your baseUrl.")
            return integrationConfig.baseUrl
        }

        return host
    }
}

@objc(AuthorizationProviderType)
public protocol AuthorizationProviderType {
    init()
    func getAuthorizationToken() -> String?
    @objc optional func getAuthorizationHeader() -> String?
}
