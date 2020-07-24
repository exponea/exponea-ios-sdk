//
//  DatabaseManagerError.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 10/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// Data types that thrown the possible errors while trying to save data into coredata.
///
/// - unableToLoadPeristentStore: When CoreData fails loading a persistent store.
/// - objectDoesNotExist: Object requested does not exist.
/// - wrongObjectType: Error while trying to cast the coredata objects.
/// - saveCustomerFailed: Error while trying to save a customer data into coredata.
/// - unknownError: Invalid error while trying to manipulate the data.
public enum DatabaseManagerError: LocalizedError {
    case unableToCreatePersistentContainer
    case unableToLoadPeristentStore(String)
    case notEnoughDiskSpace(String)
    case objectDoesNotExist
    case wrongObjectType
    case saveCustomerFailed(String)
    case unknownError(String?)

    public var errorDescription: String? {
        switch self {
        case .unableToCreatePersistentContainer:
            return "Unable to create persistant container for database."

        case .unableToLoadPeristentStore(let details):
            return "Unable to load persistent store for database: \(details)"

        case .notEnoughDiskSpace(let details):
            return "Not enough disk space: \(details)"

        case .objectDoesNotExist:
            return "Object does not exist."

        case .wrongObjectType:
            return "The object you want to modify is of different type than expected."

        case .saveCustomerFailed(let details):
            return "Saving a new customer failed: \(details)."

        case .unknownError(let details):
            return "Unknown database error: \(details ?? "N/A")"
        }
    }
}
