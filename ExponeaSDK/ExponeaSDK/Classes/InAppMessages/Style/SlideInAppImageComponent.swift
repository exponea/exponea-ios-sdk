//
//  SlideInAppImageComponent.swift
//  ExponeaSDK
//
//  Created by Ankmara on 18.03.2025.
//  Copyright © 2025 Exponea. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

public struct SlideInAppImageComponent: View, InAppImageSizing {

    @State var config: InAppImageComponentConfig
    private let layoutConfig: InAppLayoutConfig
    private let preloadedImage: UIImage?

    public init(
        config: InAppImageComponentConfig,
        layoutConfig: InAppLayoutConfig,
        preloadedImage: UIImage? = nil
    ) {
        self.layoutConfig = layoutConfig
        self.config = config
        self.preloadedImage = preloadedImage
    }

    var width: CGFloat {
        if config.size == .fullscreen {
            let layoutLeading = layoutConfig.margin.first(where: { $0.edge == .leading })?.value ?? 0
            let layoutTrailing = layoutConfig.margin.first(where: { $0.edge == .trailing })?.value ?? 0
            let width = UIScreen.main.bounds.width
            return width - layoutLeading - layoutTrailing + (config.cornerRadius ?? 0)
        } else {
            return 80
        }
    }

    public var body: some View {
        if config.isVisible && (config.url != nil || preloadedImage != nil) {
            VStack(spacing: 0) {
                if let preloadedImage {
                    imageContent(Image(uiImage: preloadedImage), imageSize: preloadedImage.size, fullscreenFillsWidth: false)
                } else {
                    ExponeaAsyncImage(url: config.url) { image, imageSize in
                        imageContent(image, imageSize: imageSize, fullscreenFillsWidth: false)
                    } placeholder: {
                        Color(.clear)
                    }
                }
            }
            .frame(width: width)
        } else {
            EmptyView()
        }
    }
}
