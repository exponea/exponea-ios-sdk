//
//  InAppImageComponent.swift
//  ExponeaSDK
//
//  Created by Ankmara on 06.11.2024.
//  Copyright © 2024 Exponea. All rights reserved.
//

import SwiftUI
import UIKit
import Combine

public struct InAppImageComponent: View, InAppImageSizing {

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
        let layoutLeading = layoutConfig.margin.first(where: { $0.edge == .leading })?.value ?? 0
        let layoutTrailing = layoutConfig.margin.first(where: { $0.edge == .trailing })?.value ?? 0
        let trailing = config.margin.first(where: { $0.edge == .trailing })?.value ?? 0
        let leading = config.margin.first(where: { $0.edge == .leading })?.value ?? 0
        var result = UIScreen.main.bounds.width - trailing - leading - layoutLeading - layoutTrailing
        if case .fullscreen = config.size {
            return result
        }
        let layoutPadLeading = layoutConfig.padding.first(where: { $0.edge == .leading })?.value ?? 0
        let layoutPadTrailing = layoutConfig.padding.first(where: { $0.edge == .trailing })?.value ?? 0
        result -= layoutPadLeading + layoutPadTrailing
        return result
    }

    public var body: some View {
        if config.isVisible {
            VStack(spacing: 0) {
                if let preloadedImage {
                    imageContent(Image(uiImage: preloadedImage), imageSize: preloadedImage.size)
                } else {
                    ExponeaAsyncImage(url: config.url) { image, imageSize in
                        imageContent(image, imageSize: imageSize)
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
