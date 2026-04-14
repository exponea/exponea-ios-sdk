//
//  IntegrationSourceType.swift
//  ExponeaSDK
//
//  Created by Bloomreach on 09/01/2026.
//  Copyright © 2026 Exponea. All rights reserved.
//

import Foundation

public enum IntegrationSourceType: Equatable, Codable {

    case project(projectToken: String)
    case stream(streamId: String)

    /// Discriminator string for storage and comparison (e.g. Core Data `integrationType` column).
    public var rawValue: String {
        switch self {
        case .project: return "project"
        case .stream: return "stream"
        }
    }

    public var integrationId: String {
        switch self {
        case .project(let projectToken):
            return projectToken
        case .stream(let streamId):
            return streamId
        }
    }

    /// Returns true if this is a Stream/Data Hub integration; false for Project/Engagement.
    /// Single canonical flag; prefer explicit `switch self` at call sites.
    public var isStream: Bool {
        switch self {
        case .project: return false
        case .stream: return true
        }
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case type
        case projectToken
        case streamId
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "project":
            let token = try container.decode(String.self, forKey: .projectToken)
            self = .project(projectToken: token)
        case "stream":
            let id = try container.decode(String.self, forKey: .streamId)
            self = .stream(streamId: id)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown IntegrationSourceType: \(type)"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .project(let projectToken):
            try container.encode("project", forKey: .type)
            try container.encode(projectToken, forKey: .projectToken)
        case .stream(let streamId):
            try container.encode("stream", forKey: .type)
            try container.encode(streamId, forKey: .streamId)
        }
    }
}
