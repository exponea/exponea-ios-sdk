//
//  RequestParametersType.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 27/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

protocol RequestParametersType {
    var parameters: [AnyHashable: JSONConvertible] { get }
}
