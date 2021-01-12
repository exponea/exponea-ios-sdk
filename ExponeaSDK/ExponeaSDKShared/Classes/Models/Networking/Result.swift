//
//  Result.swift
//  ExponeaSDKShared
//
//  Created by Ricardo Tokashiki on 20/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// Data type used to return the result of a http call. It returns the status and
/// the object in case of success, otherwise return the error from the Exponea API.
///
/// - success(T)
/// - failure(Error)
public enum Result<T> {
    case success(T)
    case failure(Error)

    public var value: T? {
        if case .success(let value) = self {
            return value
        } else {
            return nil
        }
    }

    public var error: Error? {
        if case .failure(let error) = self {
            return error
        } else {
            return nil
        }
    }
}

/// Data type used for request http calls when the sdk does not return any value
/// when the result is success. For error messages it return the error from the Exponea API.
/// Used for cases like flushing the data to the Exponea API.
///
/// - success
/// - failure(Error)
public enum EmptyResult<T: Error> {
    case success
    case failure(T)

    public var error: T? {
        if case .failure(let error) = self {
            return error
        } else {
            return nil
        }
    }
}
