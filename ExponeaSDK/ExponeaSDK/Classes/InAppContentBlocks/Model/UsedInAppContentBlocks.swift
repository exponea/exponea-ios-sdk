//
//  UsedInAppContentBlocks.swift
//  ExponeaSDK
//
//  Created by Ankmara on 10.07.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation

public struct UsedInAppContentBlocks: Hashable {
    public var tag: Int
    public var indexPath: IndexPath
    public var messageId: String
    public var placeholder: String
    public var height: CGFloat
    public var hasBeenLoaded = false
    public var isActive = false
}
