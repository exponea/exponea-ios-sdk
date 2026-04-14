//
//  TrackingObject.swift
//  ExponeaSDKShared
//
//  Created by Panaxeo on 05/03/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation

public protocol TrackingObject {
    var exponeaProject: any ExponeaIntegrationType { get }
    var customerIds: [String: String] { get }
    var dataTypes: [DataType] { get }
    var timestamp: Double { get }
}

public final class EventTrackingObject: TrackingObject, Equatable, Codable {
    public let exponeaProject: any ExponeaIntegrationType
    public let customerIds: [String: String]
    public let eventType: String?
    public let timestamp: Double
    public let dataTypes: [DataType]

    public init(
        exponeaProject: any ExponeaIntegrationType,
        customerIds: [String: String],
        eventType: String?,
        timestamp: Double,
        dataTypes: [DataType]
    ) {
        self.exponeaProject = exponeaProject
        self.customerIds = customerIds
        self.eventType = eventType
        self.timestamp = timestamp
        self.dataTypes = dataTypes
    }

    public static func == (lhs: EventTrackingObject, rhs: EventTrackingObject) -> Bool {
        func areExponeaProjectsEqual(
            _ lhs: any ExponeaIntegrationType,
            _ rhs: any ExponeaIntegrationType
        ) -> Bool {
            guard lhs.type == rhs.type else { return false }
            switch lhs.type {
            case .project:
                guard let leftSide = lhs as? ExponeaProject, let rightSide = rhs as? ExponeaProject else { return false }
                return leftSide == rightSide
            case .stream:
                guard let leftSide = lhs as? ExponeaIntegration, let rightSide = rhs as? ExponeaIntegration else { return false }
                return leftSide == rightSide
            }
        }
        
        return areExponeaProjectsEqual(lhs.exponeaProject, rhs.exponeaProject)
            && lhs.customerIds == rhs.customerIds
            && lhs.eventType == rhs.eventType
            && lhs.timestamp == rhs.timestamp
            && lhs.dataTypes == rhs.dataTypes
    }
    
    public static func deserialize(from data: Data) -> EventTrackingObject? {
        return try? JSONDecoder.snakeCase.decode(EventTrackingObject.self, from: data)
    }

    public func serialize() -> Data? {
        return try? JSONEncoder.snakeCase.encode(self)
    }
    
    // MARK: - Codable
    
    public enum CodingKeys: CodingKey {
        case exponeaProject
        case customerIds
        case eventType
        case timestamp
        case dataTypes
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let project = try? container.decodeIfPresent(ExponeaProject.self, forKey: .exponeaProject) {
            exponeaProject = project
        } else {
            exponeaProject = try container.decode(ExponeaIntegration.self, forKey: .exponeaProject)
        }
        
        customerIds = try container.decode([String: String].self, forKey: .customerIds)
        eventType = try container.decodeIfPresent(String.self, forKey: .eventType)
        timestamp = try container.decode(Double.self, forKey: .timestamp)
        dataTypes = try container.decode([DataType].self, forKey: .dataTypes)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch exponeaProject.type {
        case .project:
            if let project = exponeaProject as? ExponeaProject {
                try container.encode(project, forKey: .exponeaProject)
            }
        case .stream:
            if let stream = exponeaProject as? ExponeaIntegration {
                try container.encode(stream, forKey: .exponeaProject)
            }
        }
        
        try container.encode(customerIds, forKey: .customerIds)
        try container.encodeIfPresent(eventType, forKey: .eventType)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(dataTypes, forKey: .dataTypes)
    }
}

public final class CustomerTrackingObject: TrackingObject {
    public let exponeaProject: any ExponeaIntegrationType
    public let customerIds: [String: String]
    public let timestamp: Double
    public let dataTypes: [DataType]

    public init(
        exponeaProject: any ExponeaIntegrationType,
        customerIds: [String: String],
        timestamp: Double,
        dataTypes: [DataType]
    ) {
        self.exponeaProject = exponeaProject
        self.customerIds = customerIds
        self.timestamp = timestamp
        self.dataTypes = dataTypes
    }
}

public extension TrackingObject {
    static func loadCustomerIdsFromUserDefaults(appGroup: String) -> [String: String]? {
        guard let userDefaults = UserDefaults(suiteName: appGroup),
              let data = userDefaults.data(forKey: Constants.General.lastKnownCustomerIds) else {
            return nil
        }
        return try? JSONDecoder().decode([String: String].self, from: data)
    }
}
