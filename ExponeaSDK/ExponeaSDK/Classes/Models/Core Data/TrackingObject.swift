//
//  TrackingObject.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 05/03/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation

protocol TrackingObject {
    var projectToken: String? { get }
    var dataTypes: [DataType] { get }
    var timestamp: Double { get }
}

final class EventTrackingObject: TrackingObject {
    public let projectToken: String?
    public let eventType: String?
    public let timestamp: Double
    public let dataTypes: [DataType]

    public init(projectToken: String?, eventType: String?, timestamp: Double, dataTypes: [DataType]) {
        self.projectToken = projectToken
        self.eventType = eventType
        self.timestamp = timestamp
        self.dataTypes = dataTypes
    }
}

final class CustomerTrackingObject: TrackingObject {
    public let projectToken: String?
    public let timestamp: Double
    public let dataTypes: [DataType]

    public init(projectToken: String?, timestamp: Double, dataTypes: [DataType]) {
        self.projectToken = projectToken
        self.timestamp = timestamp
        self.dataTypes = dataTypes
    }
}
