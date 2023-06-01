//
//  ImageViewStyle.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 19/05/2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation
import UIKit

public class ImageViewStyle {
    var visible: Bool?
    var backgroundColor: String?

    public init(visible: Bool? = nil, backgroundColor: String? = nil) {
        self.visible = visible
        self.backgroundColor = backgroundColor
    }

    public func applyTo(_ target: UIView) {
        if let visible = visible {
            target.isHidden = !visible
        }
        if let backgroundColor = UIColor.parse(backgroundColor) {
            target.tintColor = backgroundColor
        }
    }

    public func applyTo(_ target: UIImageView) {
        if let visible = visible {
            target.isHidden = !visible
        }
        if let backgroundColor = UIColor.parse(backgroundColor) {
            target.backgroundColor = backgroundColor
        }
    }
}
