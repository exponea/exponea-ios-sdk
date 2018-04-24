//
//  CustomerRecommendation.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 11/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

public struct CustomerRecommendation {
    public var type: String
    public var id: String
    public var size: Int?
    public var strategy: String?
    public var knowItems: Bool?
    public var anti: Bool?
    public var items: [KeyValueItem]?
}
