//
//  CustomerEventsModel.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 11/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

public struct CustomerEventsModel {
    public var eventTypes: [String]
    public var sortOrder: String = "asc"
    public var limit: Int = 1
    public var skip: Int = 100
}
