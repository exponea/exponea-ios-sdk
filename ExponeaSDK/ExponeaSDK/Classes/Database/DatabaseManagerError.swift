//
//  DatabaseManagerError.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 10/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

enum DatabaseManagerError: Error {
    case objectDoesNotExist
    case wrongObjectType
    case unknownError(String?)
    
    var localizedDescription: String {
        switch self {
        case .objectDoesNotExist:
            return "Object does not exist."
            
        case .wrongObjectType:
            return "The object you want to modify is of different type than expected."
            
        case .unknownError(let details):
            return "Unknown error. \(details != nil ? details! : "")"
        }
    }
}
