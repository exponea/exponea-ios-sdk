//
//  DatabaseManagerError.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 10/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

public enum DatabaseManagerError: LocalizedError {
    case objectDoesNotExist
    case wrongObjectType
    case saveCustomerFailed(String)
    case unknownError(String?)
    
    public var errorDescription: String? {
        switch self {
        case .objectDoesNotExist:
            return "Object does not exist."
            
        case .wrongObjectType:
            return "The object you want to modify is of different type than expected."
        
        case .saveCustomerFailed(let details):
            return "Saving a new customer failed: \(details)."
            
        case .unknownError(let details):
            return "Unknown error. \(details != nil ? details! : "")"
        }
    }
}
