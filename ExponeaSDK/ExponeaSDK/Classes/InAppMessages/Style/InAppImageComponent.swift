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

public struct InAppImageComponent: View {

    @State var config: InAppImageComponentConfig
    private let layoutConfig: InAppLayoutConfig

    public init(config: InAppImageComponentConfig, layoutConfig: InAppLayoutConfig) {
        self.layoutConfig = layoutConfig
        self.config = config
    }

    private var width: CGFloat {
        let layoutLeading = layoutConfig.margin.first(where: { $0.edge == .leading })?.value ?? 0
        let layoutTrailing = layoutConfig.margin.first(where: { $0.edge == .trailing })?.value ?? 0
        let trailing = config.margin.first(where: { $0.edge == .trailing })?.value ?? 0
        let leading = config.margin.first(where: { $0.edge == .leading })?.value ?? 0
        return UIScreen.main.bounds.width - trailing - leading - layoutLeading - layoutTrailing
    }

    private func getHeightFromAspectRation(aspectRation: CGSize) -> CGFloat {
        let screenWidth = width
        let aspectRatio: CGFloat = aspectRation.width / aspectRation.height
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
                            .frame(maxWidth: width, maxHeight: getHeightFromAspectRation(aspectRation: .init(width: 1, height: 1)), alignment: .center)
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
                            .frame(maxWidth: .infinity)
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
