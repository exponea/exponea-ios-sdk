//
//  TrackingManager.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 11/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

class TrackingManager {
    let database: DatabaseManagerType
    let repository: TrackingRepository

    init(database: DatabaseManagerType, repository: TrackingRepository) {
        self.database = database
        self.repository = repository
    }
}

extension TrackingManager: TrackingManagerType {
    func trackEvent(_ type: EventType, customData: [String: Any]?) -> Bool {

        guard let projectToken = Exponea.shared.projectToken else {
            return false
        }

        switch type {
        case .install:
            return installEvent(projectToken: projectToken)
        case .sessionStart:
            // TODO: save to db
            return false

        case .sessionEnd:
            // TODO: save to db
            return false

        case .event:
            // TODO: save to db
            return false

        case .track:
            // TODO: save to db
            return false

        case .custom(let value):
            // TODO: save to db
            return false
        }
    }
}

extension TrackingManager {
    func installEvent(projectToken: String) -> Bool {
        return database.trackInstall(projectToken: projectToken,
                                     properties: DeviceProperties().asKeyValueModel())
    }
}
