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
    var parameters: [String: JSONValue] { get }
    var requestParameters: [String: Any] { get }
}

extension RequestParametersType {
    var requestParameters: [String: Any] {
        return parameters.mapValues { $0.rawValue }
    }
}
