//
//  UsedInAppContentBlocks.swift
//  ExponeaSDK
//
//  Created by Ankmara on 10.07.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation

public struct UsedInAppContentBlocks {
    public var tag: Int
    public var indexPath: IndexPath
    public var messageId: String
    public var placeholder: String
    public var height: CGFloat
    public var hasBeenLoaded = false
    public var placeholderData: InAppContentBlockResponse?
    public var isActive = false

    init(
        tag: Int,
        indexPath: IndexPath,
        messageId: String,
        placeholder: String,
        height: CGFloat,
        hasBeenLoaded: Bool = false,
        isActive: Bool = false,
        placeholderData: InAppContentBlockResponse? = nil
    ) {
        self.tag = tag
        self.indexPath = indexPath
        self.messageId = messageId
        self.placeholder = placeholder
        self.height = height
        self.hasBeenLoaded = hasBeenLoaded
        self.placeholderData = placeholderData
    }
    
    func describeDetailed() -> String {
        return """
        {
            tag: \(tag),
            indexPath: \(indexPath),
            messageId: \(messageId),
            placeholder: \(placeholder),
            height: \(height),
            hasBeenLoaded: \(hasBeenLoaded),
            placeholderData: \(String(describing: placeholderData?.describe())),
            isActive: \(isActive)
        }
        """
    }
}
