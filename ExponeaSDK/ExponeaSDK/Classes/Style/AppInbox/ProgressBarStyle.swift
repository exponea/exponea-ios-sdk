//
//  ProgressBarStyle.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 19/05/2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation
import UIKit

public class ProgressBarStyle {
    var visible: Bool?
    var progressColor: String?
    var backgroundColor: String?

    public init(visible: Bool? = nil, progressColor: String? = nil, backgroundColor: String? = nil) {
        self.visible = visible
        self.progressColor = progressColor
        self.backgroundColor = backgroundColor
    }

    public func applyTo(_ target: UIActivityIndicatorView) {
        if let visible = visible {
            target.isHidden = !visible
        }
        if let progressColor = UIColor.parse(progressColor) {
            target.tintColor = progressColor
        }
        if let backgroundColor = UIColor.parse(backgroundColor) {
            target.backgroundColor = backgroundColor
        }
    }
}
