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
    public internal(set) var projectMapping: [EventType: [ExponeaProject]]?
    public internal(set) var projectToken: String
    public internal(set) var authorization: Authorization = .none
    public internal(set) var baseUrl: String = Constants.Repository.baseUrl
    public var inAppContentBlocksPlaceholders: [String]?
    public var defaultProperties: [String: JSONConvertible]?
    public var sessionTimeout: Double = Constants.Session.defaultTimeout
    public var automaticSessionTracking: Bool = true

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
    }

    /// Creates the configuration object with the provided properties.
    ///
    /// - Parameters:
    ///   - projectToken: The project token used for connecting with Exponea.
    ///   - projectMapping: Optional project mapping if you wish to send events to different projects.
    ///   - authorization: The authorization you want to use when tracking events.
    ///   - baseUrl: Your API base URL that the SDK will connect to.
    ///   - defaultProperties: Custom properties to be tracked in every event.
    ///   - advancedAuthEnabled: Flag if advanced authorization used for communication with BE
    public init(projectToken: String?,
                projectMapping: [EventType: [ExponeaProject]]? = nil,
                authorization: Authorization,
                baseUrl: String?,
                appGroup: String? = nil,
                defaultProperties: [String: JSONConvertible]? = nil,
                inAppContentBlocksPlaceholders: [String]? = nil,
                allowDefaultCustomerProperties: Bool? = nil,
                advancedAuthEnabled: Bool? = nil,
                isDarkModeEnabled: Bool? = nil,
                appInboxDetailImageInset: CGFloat? = 56,
                manualSessionAutoClose: Bool = true
    ) throws {
        guard let projectToken = projectToken else {
            throw ExponeaError.configurationError("No project token provided.")
        }
        self.projectToken = projectToken
        self.projectMapping = projectMapping
        self.authorization = authorization
        self.appGroup = appGroup
        self.defaultProperties = defaultProperties
        self.allowDefaultCustomerProperties = allowDefaultCustomerProperties ?? true
        self.advancedAuthEnabled = advancedAuthEnabled ?? false
        self.inAppContentBlocksPlaceholders = inAppContentBlocksPlaceholders
        self.appInboxDetailImageInset = appInboxDetailImageInset
        self.manualSessionAutoClose = manualSessionAutoClose
        if let url = baseUrl {
            self.baseUrl = url
        }
        if (self.advancedAuthEnabled) {
            self.customAuthProvider = try loadCustomAuthProvider()
        }
        try self.validate()
        self.isDarkModeEnabled = isDarkModeEnabled ?? false
    }

    public init(
        projectToken: String,
        projectMapping: [EventType: [ExponeaProject]]?,
        authorization: Authorization = .none,
        baseUrl: String,
        defaultProperties: [String: JSONConvertible]?,
        inAppContentBlocksPlaceholders: [String]? = nil,
        sessionTimeout: Double,
        automaticSessionTracking: Bool = true,
        automaticPushNotificationTracking: Bool,
        requirePushAuthorization: Bool = true,
        tokenTrackFrequency: TokenTrackFrequency,
        appGroup: String?,
        flushEventMaxRetries: Int,
        allowDefaultCustomerProperties: Bool?,
        advancedAuthEnabled: Bool?,
        isDarkModeEnabled: Bool? = nil,
        appInboxDetailImageInset: CGFloat? = 56,
        manualSessionAutoClose: Bool = true
    ) throws {
        self.projectToken = projectToken
        self.projectMapping = projectMapping
        self.authorization = authorization
        self.baseUrl = baseUrl
        self.defaultProperties = defaultProperties
        self.inAppContentBlocksPlaceholders = inAppContentBlocksPlaceholders
        self.sessionTimeout = sessionTimeout
        self.automaticSessionTracking = automaticSessionTracking
        self.automaticPushNotificationTracking = automaticPushNotificationTracking
        self.requirePushAuthorization = requirePushAuthorization
        self.tokenTrackFrequency = tokenTrackFrequency
        self.appGroup = appGroup
        self.flushEventMaxRetries = flushEventMaxRetries
        self.allowDefaultCustomerProperties = allowDefaultCustomerProperties ?? true
        self.advancedAuthEnabled = advancedAuthEnabled ?? false
        self.appInboxDetailImageInset = appInboxDetailImageInset
        self.manualSessionAutoClose = manualSessionAutoClose
        if (self.advancedAuthEnabled) {
            self.customAuthProvider = try loadCustomAuthProvider()
        }
        try self.validate()
        self.isDarkModeEnabled = isDarkModeEnabled ?? false
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
            if (self.advancedAuthEnabled) {
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

        // Project token
        guard let projectToken = try container.decodeIfPresent(String.self, forKey: .projectToken) else {
            throw ExponeaError.configurationError("No project token provided.")
        }
        self.projectToken = projectToken

        // Base URL
        if let baseUrl = try container.decodeIfPresent(String.self, forKey: .baseUrl) {
            self.baseUrl = baseUrl
        }

        // Authorization
        if let authorization = try container.decodeIfPresent(Authorization.self, forKey: .authorization) {
            self.authorization = authorization
        }

        // Project token mapping
        if let dictionary = try container.decodeIfPresent(
            Dictionary<String, [ExponeaProject]>.self, forKey: .projectMapping) {
            var mapping: [EventType: [ExponeaProject]] = [:]
            for (_, element: (key: event, value: projectArray)) in dictionary.enumerated() {
                guard let eventType = EventType(rawValue: event) else { continue }
                mapping[eventType] = projectArray
            }
            self.projectMapping = mapping
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

        // Advanced auth provider
        if self.advancedAuthEnabled {
            self.customAuthProvider = try loadCustomAuthProvider()
        }
        try self.validate()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let mapping = projectMapping {
            let projectMappingWithStringKeys = Dictionary(
                uniqueKeysWithValues: mapping.map { (key: EventType, value: [ExponeaProject]) in (key.rawValue, value) }
            )
            try container.encode(projectMappingWithStringKeys, forKey: .projectMapping)
        }
        try container.encode(projectToken, forKey: .projectToken)
        try container.encode(authorization, forKey: .authorization)
        try container.encode(baseUrl, forKey: .baseUrl)
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
    }

    public static func == (lhs: Configuration, rhs: Configuration) -> Bool {
        return
            lhs.projectMapping == rhs.projectMapping &&
            lhs.projectToken == rhs.projectToken &&
            lhs.authorization == rhs.authorization &&
            lhs.baseUrl == rhs.baseUrl &&
            lhs.defaultProperties?.mapValues { $0.jsonValue } == rhs.defaultProperties?.mapValues { $0.jsonValue } &&
            lhs.sessionTimeout == rhs.sessionTimeout &&
            lhs.automaticSessionTracking == rhs.automaticSessionTracking &&
            lhs.automaticPushNotificationTracking == rhs.automaticPushNotificationTracking &&
            lhs.requirePushAuthorization == rhs.requirePushAuthorization &&
            lhs.tokenTrackFrequency == rhs.tokenTrackFrequency &&
            lhs.appGroup == rhs.appGroup &&
            lhs.flushEventMaxRetries == rhs.flushEventMaxRetries &&
            lhs.allowDefaultCustomerProperties == rhs.allowDefaultCustomerProperties &&
            lhs.advancedAuthEnabled == rhs.advancedAuthEnabled
    }
}

extension Configuration {
    public func projects(for eventType: EventType) -> [ExponeaProject] {
        var projects: [ExponeaProject] = [mainProject]
        if let mapping = projectMapping, let mappedTokens = mapping[eventType] {
            projects.append(contentsOf: mappedTokens)
        }
        return projects
    }

    public var mainProject: ExponeaProject {
        ExponeaProject(baseUrl: baseUrl, projectToken: projectToken, authorization: authorization)
    }

    /// Returns ExponeaProject that:
    /// - contains CustomerID auth token if AuthProvider is registered
    /// - contains Api auth token otherwise
    /// !!! Access it in background thread due to possibility of fetching of Customer Token value
    public var mutualExponeaProject: ExponeaProject {
        guard let customAuthProvider = self.customAuthProvider else {
            return mainProject
        }
        let authToken = customAuthProvider.getAuthorizationToken()
        let authorization: Authorization
        if let authToken = authToken, !authToken.isEmpty {
            authorization = .bearer(token: authToken)
        } else {
            authorization = .none
        }
        return ExponeaProject(
            baseUrl: baseUrl,
            projectToken: projectToken,
            authorization: authorization
        )
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

        if let mapping = projectMapping {
            text += "Project Token Mapping: \(mapping)\n"
        }

        text += "Project Token: \(projectToken)\n"

        if let defaultProperties = defaultProperties {
            text += "Default Attributes: \(defaultProperties)\n"
        }

        text += """
        Authorization: \(authorization)
        Base URL: \(baseUrl)
        Session Timeout: \(sessionTimeout)
        Automatic Session Tracking: \(automaticSessionTracking)
        Automatic Push Notification Tracking: \(automaticPushNotificationTracking)
        Require Push Authorization: \(requirePushAuthorization)
        Token Track Frequency: \(tokenTrackFrequency)
        Flush Event Max Retries: \(flushEventMaxRetries)
        App Group: \(appGroup ?? "not configured")
        Default Customer Props allowed: \(allowDefaultCustomerProperties)
        Advanced authorization Enabled: \(advancedAuthEnabled)
        """

        return text
    }

    /// Returns the hostname based on the baseUrl value.
    public var hostname: String {
        guard let components = URLComponents(string: baseUrl),
            let host = components.host else {
            Exponea.logger.log(.warning, message: "Can't get URL components from baseUrl, check your baseUrl.")
            return baseUrl
        }

        return host
    }
}

@objc(AuthorizationProviderType)
public protocol AuthorizationProviderType {
    init()
    func getAuthorizationToken() -> String?
}
