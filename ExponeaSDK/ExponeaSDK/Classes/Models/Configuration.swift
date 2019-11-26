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
public struct Configuration: Decodable {
    public internal(set) var projectMapping: [EventType: [String]]?
    public internal(set) var projectToken: String?
    public internal(set) var authorization: Authorization = .none
    public internal(set) var baseUrl: String = Constants.Repository.baseUrl
    public internal(set) var defaultProperties: [String: JSONConvertible]?
    public internal(set) var sessionTimeout: Double = Constants.Session.defaultTimeout
    public internal(set) var automaticSessionTracking: Bool = true

    /// If enabled, will swizzle default push notifications methods and functions and automatically
    /// listen to updates for tokens or push settings.
    public internal(set) var automaticPushNotificationTracking: Bool = true

    /// If automatic push notification tracking is enabled, this can be used to determine how often
    /// should the push notification token be sent to Exponea.
    public internal(set) var tokenTrackFrequency: TokenTrackFrequency = .onTokenChange

    /// App group is used when push notification data is shared among service or content extensions.
    /// This is required for tracking delivered push notifications properly.
    public internal(set) var appGroup: String?

    /// The maximum amount of retries before a flush event is considered as invalid and deleted from the database.
    public internal(set) var flushEventMaxRetries: Int = Constants.Session.maxRetries

    enum CodingKeys: String, CodingKey {
        case projectMapping
        case projectToken
        case sessionTimeout
        case automaticSessionTracking
        case automaticPushNotificationTracking
        case tokenTrackFrequency
        case authorization
        case baseUrl
        case flushEventMaxRetries
        case appGroup
        case defaultProperties
    }

    private init() {}

    /// Creates the configuration object with the provided properties.
    ///
    /// - Parameters:
    ///   - projectToken: The project token used for connecting with Exponea.
    ///   - projectMapping: Optional project token mapping if you wish to send events to different projects.
    ///   - authorization: The authorization you want to use when tracking events.
    ///   - baseUrl: Your API base URL that the SDK will connect to.
    ///   - defaultProperties: Custom properties to be tracked in every event.
    public init(projectToken: String?,
                projectMapping: [EventType: [String]]? = nil,
                authorization: Authorization,
                baseUrl: String?,
                appGroup: String? = nil,
                defaultProperties: [String: JSONConvertible]? = nil) throws {
        guard let projectToken = projectToken else {
            throw ExponeaError.configurationError("No project token provided.")
        }

        self.projectToken = projectToken
        self.projectMapping = projectMapping
        self.authorization = authorization
        self.appGroup = appGroup
        self.defaultProperties = defaultProperties

        if let url = baseUrl {
            self.baseUrl = url
        }

        try self.validate()
    }

    init(
        projectToken: String,
        projectMapping: [EventType: [String]]?,
        authorization: Authorization = .none,
        baseUrl: String,
        defaultProperties: [String: JSONConvertible]?,
        sessionTimeout: Double,
        automaticSessionTracking: Bool = true,
        automaticPushNotificationTracking: Bool,
        tokenTrackFrequency: TokenTrackFrequency,
        appGroup: String?,
        flushEventMaxRetries: Int
    ) throws {
        self.projectToken = projectToken
        self.projectMapping = projectMapping
        self.authorization = authorization
        self.baseUrl = baseUrl
        self.defaultProperties = defaultProperties
        self.sessionTimeout = sessionTimeout
        self.automaticSessionTracking = automaticSessionTracking
        self.automaticPushNotificationTracking = automaticPushNotificationTracking
        self.tokenTrackFrequency = tokenTrackFrequency
        self.appGroup = appGroup
        self.flushEventMaxRetries = flushEventMaxRetries

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

            try self.validate()

            // Stop if we found the file and decoded successfully
            return
        }
    }

    // MARK: - Decodable -

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Project token
        if let projectToken = try container.decodeIfPresent(String.self, forKey: .projectToken) {
            self.projectToken = projectToken
        }

        // Base URL
        if let baseUrl = try container.decodeIfPresent(String.self, forKey: .baseUrl) {
            self.baseUrl = baseUrl
        }

        // Authorization
        if let authorization = try container.decodeIfPresent(String.self, forKey: .authorization) {
            let components = authorization.split(separator: " ")

            if components.count == 2 {
                switch components.first {
                case "Token": self.authorization = .token(String(components[1]))
                default: break
                }
            }
        }

        // Project token mapping
        if let dictionary = try container.decodeIfPresent(
            Dictionary<String, [String]>.self, forKey: .projectMapping) {
            var mapping: [EventType: [String]] = [:]
            for (_, element: (key: event, value: tokenArray)) in dictionary.enumerated() {
                guard let eventType = EventType(rawValue: event) else { continue }
                mapping[eventType] = tokenArray
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
    }
}

extension Configuration {

    /// <#Description#>
    ///
    /// - Parameter eventType: <#eventType description#>
    /// - Returns: <#return value description#>
    func tokens(for eventType: EventType) -> [String] {
        /// Check if we have project mapping, otherwise fall back to project token if present.
        guard let mapping = projectMapping else {
            guard let projectToken = projectToken else {
                Exponea.logger.log(.error, message: "No project token or token mapping found.")
                return []
            }

            return [projectToken]
        }

        /// Return correct token mapping if present and not empty.
        if let tokens = mapping[eventType], !tokens.isEmpty {
            return tokens
        } else {
            /// First check if we have default token
            if let token = projectToken {
                return [token]
            }

            /// If we have no project token nor token mapping, fail and log error.
            guard let first = mapping.first else {
                Exponea.logger.log(.error, message: "No project token found.")
                return []
            }

            /// Otherwise grab first token in token mapping and warn about falling back to it.
            Exponea.logger.log(.warning, message: "No token mapping found for event, falling back to \(first.key).")
            return first.value
        }
    }

    /// Returns a single token suitable for fetching customer data.
    /// By default uses same token as for the `ActionType` value `.identifyCustomer`.
    var fetchingToken: String {
        guard let projectToken = projectToken else {
            Exponea.logger.log(.warning, message: """
            No default project token found, falling back to token for identify customer event type, if possible.
            """)
            let token = tokens(for: .identifyCustomer)
            return token.first ?? ""
        }

        return projectToken
    }
}

extension Configuration: CustomStringConvertible {
    public var description: String {
        var text = "[Configuration]\n"

        if let mapping = projectMapping {
            text += "Project Token Mapping: \(mapping)\n"
        }

        if let token = projectToken {
            text += "Project Token: \(token)\n"
        }

        if let defaultProperties = defaultProperties {
            text += "Default Attributes: \(defaultProperties)\n"
        }

        text += """
        Authorization: \(authorization)
        Base URL: \(baseUrl)
        Session Timeout: \(sessionTimeout)
        Automatic Session Tracking: \(automaticSessionTracking)
        Automatic Push Notification Tracking: \(automaticPushNotificationTracking)
        Token Track Frequency: \(tokenTrackFrequency)
        Flush Event Max Retries: \(flushEventMaxRetries)
        App Group: \(appGroup ?? "not configured")
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
