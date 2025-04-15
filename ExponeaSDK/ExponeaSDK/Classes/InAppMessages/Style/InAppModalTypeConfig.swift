//
//  InAppModalTypeConfig.swift
//  ExponeaSDK
//
//  Created by Ankmara on 18.03.2025.
//  Copyright © 2025 Exponea. All rights reserved.
//

import SwiftUI

public struct InAppModalTypeConfig {

    public enum InAppModalTypeTextPosition {
        case top
        case bottom
    }

    public let backgroungColor: UIColor
    public let overlayColor: UIColor
    public let cornerRadius: CGFloat
    public let titleVisibility: Bool
    public let paragraphVisibility: Bool
    public let textPosition: InAppModalTypeTextPosition

    public init(
        backgroungColor: UIColor,
        overlayColor: UIColor,
        cornerRadius: CGFloat,
        titleVisibility: Bool,
        paragraphVisibility: Bool,
        textPosition: InAppModalTypeTextPosition
    ) {
        self.backgroungColor = backgroungColor
        self.overlayColor = overlayColor
        self.cornerRadius = cornerRadius
        self.titleVisibility = titleVisibility
        self.paragraphVisibility = paragraphVisibility
        self.textPosition = textPosition
    }
}
