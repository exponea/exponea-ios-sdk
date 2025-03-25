//
//  SlideInAppImageComponent.swift
//  ExponeaSDK
//
//  Created by Ankmara on 18.03.2025.
//  Copyright © 2025 Exponea. All rights reserved.
//

import Foundation
import SwiftUI

public struct SlideInAppImageComponent: View {

    @State var config: InAppImageComponentConfig
    private let layoutConfig: InAppLayoutConfig

    public init(config: InAppImageComponentConfig, layoutConfig: InAppLayoutConfig) {
        self.layoutConfig = layoutConfig
        self.config = config
    }

    private var width: CGFloat {
        if config.size == .fullscreen {
            let layoutLeading = layoutConfig.margin.first(where: { $0.edge == .leading })?.value ?? 0
            let layoutTrailing = layoutConfig.margin.first(where: { $0.edge == .trailing })?.value ?? 0
            let width = UIScreen.main.bounds.width
            return width - layoutLeading - layoutTrailing + (config.cornerRadius ?? 0)
        } else {
            return 80
        }
    }

    private func getHeightFromAspectRation(aspectRation: CGSize) -> CGFloat {
        let screenWidth = width
        let aspectRatio: CGFloat = aspectRation.width / aspectRation.height
        return abs(screenWidth / aspectRatio)
    }

    private func getHeightFromSize(imageSize: CGSize) -> CGFloat {
        let screenWidth = width
        let aspectRatio: CGFloat = imageSize.width / imageSize.height
        return abs(screenWidth / aspectRatio)
    }

    public var body: some View {
        if config.isVisible {
            VStack(spacing: 0) {
                ExponeaAsyncImage(url: config.url) { image in
                    switch config.size {
                    case .auto:
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: width, maxHeight: getHeightFromSize(imageSize: config.imageSize), alignment: .center)
                            .clipShape(RoundedRectangle(cornerRadius: config.cornerRadius ?? 0))
                    case let .lock(apectRatio, type):
                        switch type {
                        case .cover:
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: width, height: getHeightFromAspectRation(aspectRation: apectRatio))
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: config.cornerRadius ?? 0))
                        case .fill:
                            image
                                .resizable()
                                .aspectRatio(apectRatio, contentMode: .fill)
                                .frame(width: width, height: getHeightFromAspectRation(aspectRation: apectRatio))
                                .clipShape(RoundedRectangle(cornerRadius: config.cornerRadius ?? 0))
                        case .contain:
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .frame(height: getHeightFromAspectRation(aspectRation: apectRatio))
                                .clipShape(RoundedRectangle(cornerRadius: config.cornerRadius ?? 0))
                        case .none:
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: config.imageSize.width, height: config.imageSize.height)
                                .position(x: width / 2, y: getHeightFromAspectRation(aspectRation: apectRatio) / 2)
                                .frame(width: width, height: getHeightFromAspectRation(aspectRation: apectRatio))
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: config.cornerRadius ?? 0))
                        }
                    case .fullscreen:
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(minWidth: 0)
                            .edgesIgnoringSafeArea(.all)
                            .frame(alignment: .center)
                    }
                } placeholder: {
                    Color(.clear)
                }
            }
            .frame(width: width)
        } else {
            EmptyView()
        }
    }
}
