//
//  Authorization.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 10/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// Data type to identify which kind of authorization the sdk should use
/// when making http calls for the Exponea API.
public enum Authorization {
    case none
    case token(String)
    case basic(String)
}
