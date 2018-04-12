//
//  TrackingManagerType.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 11/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

protocol TrackingManagerType: class {
    // TODO: add other methods as necessary
    func trackEvent(_ type: EventType, customData: [String: Any]?) -> Bool
}
