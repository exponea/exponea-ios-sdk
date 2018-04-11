//
//  CustomerExportModel.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 11/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

public struct CustomerExportModel {
    public var attributes: CustomerExportAttributesModel
    public var filter: [KeyValueModel]
    public var executionTime: Int
    public var timezone: String
    public var responseFormat: String
}
