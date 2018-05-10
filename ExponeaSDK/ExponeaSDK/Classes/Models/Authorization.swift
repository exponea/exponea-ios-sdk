//
//  Authorization.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 10/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

public enum Authorization {
    case none
    case token(String)
    case basic(String)
}
