//
//  Configuration.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 06/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import CoreData

/// <#Description#>
public struct Configuration: Decodable {
    public internal(set) var projectMapping: [EventType: [String]]?
    public internal(set) var projectToken: String?
    public internal(set) var authorization: Authorization = .none
    public internal(set) var baseUrl: String = Constants.Repository.baseUrl
    public internal(set) var contentType: String = Constants.Repository.contentType
    public var sessionTimeout: Double = Constants.Session.defaultTimeout
    public var automaticSessionTracking: Bool = true
    public var automaticPushNotificationTracking: Bool = true
    
    /// The maximum amount of retries before a flush event is considered as invalid and deleted from the database.
    public var flushEventMaxRetries: Int = Constants.Session.maxRetries

    enum CodingKeys: String, CodingKey {
        case projectMapping
        case projectToken
        case sessionTimeout
        case automaticSessionTracking
        case automaticPushNotificationTracking
        case authorization
        case baseUrl
        case flushEventMaxRetries
    }

    private init() {}

    /// Creates the configuration object with the provided properties.
    ///
    /// - Parameters:
    ///   - projectToken: The project token used for connecting with Exponea.
    ///   - projectMapping: Optional project token mapping if you wish to send events to different projects.
    ///   - authorization: The authorization you want to use when tracking events.
    ///   - baseUrl: Your API base URL that the SDK will connect to.
    public init(projectToken: String?,
                projectMapping: [EventType: [String]]? = nil,
                authorization: Authorization,
                baseUrl: String?) throws {
        guard let projectToken = projectToken else {
            throw ExponeaError.configurationError("No project token provided.")
        }
        
        self.projectToken = projectToken
        self.projectMapping = projectMapping
        self.authorization = authorization
        if let url = baseUrl {
            self.baseUrl = url
        }
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
            
            // Stop if we found the file and decoded successfully
            return
        }
    }

    // MARK: - Decodable -

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let projectToken = try container.decodeIfPresent(String.self, forKey: .projectToken) {
            self.projectToken = projectToken
        }

        if let baseUrl = try container.decodeIfPresent(String.self, forKey: .baseUrl) {
            self.baseUrl = baseUrl
        }

        if let authorization = try container.decodeIfPresent(String.self, forKey: .authorization) {
            let components = authorization.split(separator: " ")
            
            if components.count == 2, components.first == "Basic" {
                self.authorization = .basic(String(components[1]))
            }
        }

        if let dictionary = try container.decodeIfPresent(Dictionary<String, [String]>.self, forKey: .projectMapping) {
            var mapping: [EventType: [String]] = [:]
            for (_, element: (key: event, value: tokenArray)) in dictionary.enumerated() {
                guard let eventType = EventType(rawValue: event) else { continue }
                mapping[eventType] = tokenArray
            }
            self.projectMapping = mapping
        }

        if let sessionTimeout = try container.decodeIfPresent(Double.self, forKey: .sessionTimeout) {
            self.sessionTimeout = sessionTimeout
        }

        if let automaticSessionTracking = try container.decodeIfPresent(Bool.self, forKey: .automaticSessionTracking) {
            self.automaticSessionTracking = automaticSessionTracking
        }
        
        if let flushEventMaxRetries = try container.decodeIfPresent(Int.self, forKey: .flushEventMaxRetries) {
            self.flushEventMaxRetries = flushEventMaxRetries
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
                Exponea.logger.log(.error, message: "No project token found.")
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
        
        text += """
        Authorization: \(authorization)
        Base URL: \(baseUrl)
        Content Type: \(contentType)
        Session Timeout: \(sessionTimeout)
        Automatic Session Tracking: \(automaticSessionTracking)
        Automatic Push Notification Tracking: \(automaticPushNotificationTracking)
        Flush Event Max Retries: \(flushEventMaxRetries)
        
        """
        
        return text
    }
}
