//
//  TrackingManagerError.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 10/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// Data types that thrown the possible errors when tracking the events.
///
/// - missingData: Holds the missing data while trying to track the events.
/// - unknownError: Holds the generic error while trying to track the events.
enum TrackingManagerError: LocalizedError {
    case cannotStartReachability
    case missingData(EventType, [DataType])
    case unknownError(String?)

    /// Return a formatted error message when sending the events to the Exponea API.
    public var errorDescription: String? {
        switch self {
        case .cannotStartReachability:
            return "Cannot start Reachability"

        case .missingData(let type, let data):
            return "Event of type \(type) is missing required data: \(data)."

        case .unknownError(let details):
            return "Unknown error. \(details ?? "")"
        }
    }

}
