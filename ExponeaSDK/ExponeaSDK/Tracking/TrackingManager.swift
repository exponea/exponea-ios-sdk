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
    func trackEvent(_ type: EventType, customData: [String : Any]) {
        switch type {
        case .install:
            // TODO: save to db
            break

        case .sessionStart:
            // TODO: save to db
            break

        case .sessionEnd:
            // TODO: save to db
            break

        case .custom(let value):
            // TODO: save to db
            break
        }
    }
}
