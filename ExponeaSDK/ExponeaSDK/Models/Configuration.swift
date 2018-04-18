//
//  Configuration.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 06/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import CoreData

struct Configuration: Decodable {
    var projectMapping: [EventType: [String]]?
    var projectToken: String?
    internal var authorization: String?
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

    public init(projectToken: String, authorization: String, baseURL: String?) {
        self.projectToken = projectToken
        self.authorization = authorization
        if let url = baseURL {
            self.baseURL = url
        }
    }

    public init(projectMapping: [EventType: [String]]) {
        self.projectMapping = projectMapping
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
            self.authorization = authorization
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
    internal var lastSessionStarted: Double {
        get {
            return UserDefaults.standard.double(forKey: Constants.Keys.sessionStarted)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.Keys.sessionStarted)
        }
    }
    internal var lastSessionEndend: Double {
        get {
            return UserDefaults.standard.double(forKey: Constants.Keys.sessionEnded)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.Keys.sessionEnded)
        }
    }
}
