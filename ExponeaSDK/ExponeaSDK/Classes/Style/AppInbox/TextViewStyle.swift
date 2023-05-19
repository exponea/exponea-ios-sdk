//
//  TextViewStyle.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 19/05/2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation
import UIKit

class TextViewStyle {
    var visible: Bool?
    var textColor: String?
    var textSize: String?
    var textWeight: String?
    var textOverride: String?

    init(
        visible: Bool? = nil,
        textColor: String? = nil,
        textSize: String? = nil,
        textWeight: String? = nil,
        textOverride: String? = nil
    ) {
        self.visible = visible
        self.textColor = textColor
        self.textSize = textSize
        self.textWeight = textWeight
        self.textOverride = textOverride
    }

    func applyTo(_ target: UILabel) {
        if let visible = visible {
            target.isHidden = !visible
        }
        if let textColor = UIColor.parse(textColor) {
            target.textColor = textColor
        }
        if let textSize = CGFloat.parse(textSize) {
            target.font = target.font?.withSize(textSize)
        }
        if let textWeight = UIFont.Weight.parse(textWeight),
           let currentFont = target.font {
            target.font = UIFont.systemFont(ofSize: currentFont.pointSize, weight: textWeight)
        }
        if let textOverride = textOverride {
            target.text = textOverride
        }
    }
}
