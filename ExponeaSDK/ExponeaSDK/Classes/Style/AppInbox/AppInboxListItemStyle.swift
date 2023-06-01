//
//  AppInboxListItemStyle.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 19/05/2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation
import UIKit

public class AppInboxListItemStyle {
    var backgroundColor: String?
    var readFlag: ImageViewStyle?
    var receivedTime: TextViewStyle?
    var title: TextViewStyle?
    var content: TextViewStyle?
    var image: ImageViewStyle?

    public init(
        backgroundColor: String? = nil,
        readFlag: ImageViewStyle? = nil,
        receivedTime: TextViewStyle? = nil,
        title: TextViewStyle? = nil,
        content: TextViewStyle? = nil,
        image: ImageViewStyle? = nil
    ) {
        self.backgroundColor = backgroundColor
        self.readFlag = readFlag
        self.receivedTime = receivedTime
        self.title = title
        self.content = content
        self.image = image
    }

    public func applyTo(_ target: MessageItemCell) {
        if let backgroundColor = UIColor.parse(backgroundColor) {
            target.backgroundColor = backgroundColor
        }
        if let readFlagStyle = readFlag {
            readFlagStyle.applyTo(target.readFlag)
        }
        if let receivedTime = receivedTime {
            receivedTime.applyTo(target.receivedTime)
        }
        if let title = title {
            title.applyTo(target.titleLabel)
        }
        if let content = content {
            content.applyTo(target.messageLabel)
        }
        if let image = image {
            image.applyTo(target.messageImage)
        }
    }
}
