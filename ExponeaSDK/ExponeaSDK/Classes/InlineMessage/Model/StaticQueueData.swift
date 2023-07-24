//
//  StaticQueueData.swift
//  ExponeaSDK
//
//  Created by Ankmara on 10.07.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

public struct StaticQueueData {
    public let tag: Int
    public let placeholderId: String
    public var completion: TypeBlock<StaticReturnData>?
}
