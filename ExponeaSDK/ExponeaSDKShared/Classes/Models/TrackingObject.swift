//
//  TrackingObject.swift
//  ExponeaSDKShared
//
//  Created by Panaxeo on 05/03/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation

public protocol TrackingObject {
    var exponeaProject: ExponeaProject { get }
    var customerIds: [String: String] { get }
    var dataTypes: [DataType] { get }
    var timestamp: Double { get }
}

public final class EventTrackingObject: TrackingObject, Equatable {
    public let exponeaProject: ExponeaProject
    public let customerIds: [String: String]
    public let eventType: String?
    public let timestamp: Double
    public let dataTypes: [DataType]

    public init(
        exponeaProject: ExponeaProject,
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
        return lhs.exponeaProject == rhs.exponeaProject
            && lhs.customerIds == rhs.customerIds
            && lhs.eventType == rhs.eventType
            && lhs.timestamp == rhs.timestamp
            && lhs.dataTypes == rhs.dataTypes
    }
}

public final class CustomerTrackingObject: TrackingObject {
    public let exponeaProject: ExponeaProject
    public let customerIds: [String: String]
    public let timestamp: Double
    public let dataTypes: [DataType]

    public init(
        exponeaProject: ExponeaProject,
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
