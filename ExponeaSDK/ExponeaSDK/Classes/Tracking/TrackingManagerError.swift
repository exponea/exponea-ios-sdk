//
//  TrackingManagerError.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 10/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// <#Description#>
///
/// - missingData: <#missingData description#>
/// - unknownError: <#unknownError description#>
public enum TrackingManagerError: LocalizedError {
    case missingData(EventType, [DataType])
    case unknownError(String?)
    
    public var errorDescription: String? {
        switch self {
        case .missingData(let type, let data):
            return "Event of type \(type) is missing required data: \(data)."
            
        case .unknownError(let details):
            return "Unknown error. \(details != nil ? details! : "")"
        }
    }
    
}
