//
//  CarouselOnChangeData.swift
//  ExponeaSDK
//
//  Created by Ankmara on 22.07.2024.
//  Copyright © 2024 Exponea. All rights reserved.
//

public struct CarouselOnChangeData {
    public let count: Int
    public let messages: [StaticReturnData]

    public init(count: Int, messages: [StaticReturnData]) {
        self.count = count
        self.messages = messages
    }
}
