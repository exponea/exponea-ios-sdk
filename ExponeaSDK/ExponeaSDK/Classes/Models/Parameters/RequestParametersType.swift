//
//  RequestParametersType.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 27/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// Protocol that group all the parameter types.
protocol RequestParametersType {
    var parameters: [AnyHashable: JSONConvertible] { get }
}
