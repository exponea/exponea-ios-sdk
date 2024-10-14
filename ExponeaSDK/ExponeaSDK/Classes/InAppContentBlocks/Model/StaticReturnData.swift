//
//  StaticReturnData.swift
//  ExponeaSDK
//
//  Created by Ankmara on 10.07.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation

public struct StaticReturnData {
    public var id = UUID()
    public let html: String
    public let tag: Int
    public var message: InAppContentBlockResponse?
}
