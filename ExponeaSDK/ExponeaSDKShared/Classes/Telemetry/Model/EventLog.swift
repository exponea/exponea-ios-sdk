//
//  EventLog.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 01/07/2025.
//  Copyright © 2025 Exponea. All rights reserved.
//

import Foundation

public struct EventLog: Codable {
    let id: String
    let name: String
    let timestamp: Double
    let runId: String
    let properties: [String: String]
    public init(name: String, runId: String, properties: [String : String]) {
        self.id = UUID().uuidString
        self.name = name
        self.timestamp = Date().timeIntervalSince1970
        self.runId = runId
        self.properties = properties
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        timestamp = try container.decodeIfPresent(Double.self, forKey: .timestamp) ?? 0
        runId = try container.decodeIfPresent(String.self, forKey: .runId) ?? ""
        properties = try container.decodeIfPresent([String: String].self, forKey: .properties) ?? [:]
    }
}
