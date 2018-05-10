//
//  Configuration.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 06/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import CoreData

public struct Configuration: Decodable {
    var projectMapping: [EventType: [String]]?
    var projectToken: String?
    internal var authorization: Authorization = .none
    internal var baseURL: String = Constants.Repository.baseURL
    internal var contentType: String = Constants.Repository.contentType
    var sessionTimeout: Double = 20
    var automaticSessionTracking: Bool = true

    enum CodingKeys: String, CodingKey {
        case projectMapping
        case projectToken
        case sessionTimeout
        case automaticSessionTracking
        case authorization
        case baseUrl
    }

    private init() {}

    public init(projectToken: String?,
                projectMapping: [EventType: [String]]? = nil,
                authorization: Authorization,
                baseURL: String?) {
        self.projectToken = projectToken
        self.projectMapping = projectMapping
        self.authorization = authorization
        if let url = baseURL {
            self.baseURL = url
        }
    }

    public init?(plistName: String) {
        for bundle in Bundle.allBundles {
            let fileName = plistName.replacingOccurrences(of: ".plist", with: "")
            if let fileURL = bundle.url(forResource: fileName, withExtension: "plist") {
                guard let data = try? Data(contentsOf: fileURL) else {
                    Exponea.logger.log(.error, message: "Can't read data from \(fileName).plist")
                    return nil
                }

                do {
                    self = try PropertyListDecoder().decode(Configuration.self, from: data)
                    return
                } catch {
                    Exponea.logger.log(.error, message: """
                        Can't parse Configuration from \(fileName).plist: \(error.localizedDescription)
                        """)
                    return nil
                }
            }
        }
    }

    // MARK: - Decodable -

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let projectToken = try container.decodeIfPresent(String.self, forKey: .projectToken) {
            self.projectToken = projectToken
        }

        if let baseUrl = try container.decodeIfPresent(String.self, forKey: .baseUrl) {
            self.baseURL = baseUrl
        }

        if let authorization = try container.decodeIfPresent(String.self, forKey: .authorization) {
            let components = authorization.split(separator: " ")
            
            if components.count == 2, components.first == "Token" {
                self.authorization = .token(String(components[1]))
            } else if components.count == 2, components.first == "Basic" {
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
    }
}

extension Configuration {
    var isConfigured: Bool {
        return projectToken != nil || projectMapping != nil
    }

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

            /// If we whae no project token nor token mapping, fail and log error.
            guard let first = mapping.first else {
                Exponea.logger.log(.error, message: "No project token found.")
                return []
            }

            /// Otherwise grab first token in token mapping and warn about falling back to it.
            Exponea.logger.log(.warning, message: "No token mapping found for event, falling back to \(first.key).")
            return first.value
        }
    }
}
