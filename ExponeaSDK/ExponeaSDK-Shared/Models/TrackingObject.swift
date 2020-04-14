//
//  TrackingObject.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 05/03/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation

protocol TrackingObject {
    var exponeaProject: ExponeaProject { get }
    var dataTypes: [DataType] { get }
    var timestamp: Double { get }
}

final class EventTrackingObject: TrackingObject, Equatable {
    public let exponeaProject: ExponeaProject
    public let eventType: String?
    public let timestamp: Double
    public let dataTypes: [DataType]

    public init(exponeaProject: ExponeaProject, eventType: String?, timestamp: Double, dataTypes: [DataType]) {
        self.exponeaProject = exponeaProject
        self.eventType = eventType
        self.timestamp = timestamp
        self.dataTypes = dataTypes
    }

    static func == (lhs: EventTrackingObject, rhs: EventTrackingObject) -> Bool {
        return lhs.exponeaProject == rhs.exponeaProject
            && lhs.eventType == rhs.eventType
            && lhs.timestamp == rhs.timestamp
            && lhs.dataTypes == rhs.dataTypes
    }
}

final class CustomerTrackingObject: TrackingObject {
    public let exponeaProject: ExponeaProject
    public let timestamp: Double
    public let dataTypes: [DataType]

    public init(exponeaProject: ExponeaProject, timestamp: Double, dataTypes: [DataType]) {
        self.exponeaProject = exponeaProject
        self.timestamp = timestamp
        self.dataTypes = dataTypes
    }
}

extension TrackingObject {
    static func loadCustomerIdsFromUserDefaults(appGroup: String) -> [String: JSONValue]? {
        guard let userDefaults = UserDefaults(suiteName: appGroup),
              let data = userDefaults.data(forKey: Constants.General.lastKnownCustomerIds) else {
            return nil
        }
        return try? JSONDecoder().decode([String: JSONValue].self, from: data)
    }
}
