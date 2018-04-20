//
//  DataType.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 18/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

public enum DataType {
    case projectToken(String)
    case customerId(KeyValueModel)
    case properties([KeyValueModel])
    case timestamp(Double?)
    case eventType(String)
    case property(String)
    case id(String)
    case recommendation(CustomerRecommendation)
    case attributes(CustomerAttributes)
    case events(CustomerEvents)
}
