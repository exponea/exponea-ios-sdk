//
//  TelemetryEventType.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 13/03/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation

enum TelemetryEventType: String {
    case initialize = "init"
    case fetchRecommendation
    case fetchConsents
    case showInAppMessage
    case selfCheck
    case anonymize
    case eventCount
}
