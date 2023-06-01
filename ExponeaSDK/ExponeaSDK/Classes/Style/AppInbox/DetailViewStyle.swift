//
//  DetailViewStyle.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 19/05/2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation

public class DetailViewStyle {
    var title: TextViewStyle?
    var content: TextViewStyle?
    var receivedTime: TextViewStyle?
    var image: ImageViewStyle?
    var button: ButtonStyle?

    public init(
        title: TextViewStyle? = nil,
        content: TextViewStyle? = nil,
        receivedTime: TextViewStyle? = nil,
        image: ImageViewStyle? = nil,
        button: ButtonStyle? = nil
    ) {
        self.title = title
        self.content = content
        self.receivedTime = receivedTime
        self.image = image
        self.button = button
    }

    public func applyTo(_ target: AppInboxDetailViewController) {
        if let title = title {
            title.applyTo(target.messageTitle)
        }
        if let content = content {
            content.applyTo(target.message)
        }
        if let receivedTime = receivedTime {
            receivedTime.applyTo(target.receivedTime)
        }
        if let image = image {
            image.applyTo(target.messageImage)
        }
        if let button = button {
            button.applyTo(target.actionMain)
            button.applyTo(target.action1)
            button.applyTo(target.action2)
            button.applyTo(target.action3)
            button.applyTo(target.action4)
        }
    }
}
