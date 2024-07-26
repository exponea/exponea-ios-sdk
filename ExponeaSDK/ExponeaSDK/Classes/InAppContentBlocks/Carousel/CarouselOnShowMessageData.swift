//
//  CarouselOnShowMessageData.swift
//  ExponeaSDK
//
//  Created by Ankmara on 22.07.2024.
//  Copyright © 2024 Exponea. All rights reserved.
//

public struct CarouselOnShowMessageData {
    public let placeholderId: String
    public let contentBlock: StaticReturnData
    public let index: Int
    public let count: Int

    public init(placeholderId: String, contentBlock: StaticReturnData, index: Int, count: Int) {
        self.placeholderId = placeholderId
        self.contentBlock = contentBlock
        self.index = index
        self.count = count
    }
}
