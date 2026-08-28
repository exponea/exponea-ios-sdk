//
//  InAppImageSizing.swift
//  ExponeaSDK
//
//  Copyright © 2025 Exponea. All rights reserved.
//

import SwiftUI

/// Shared height-calculation and rendering logic used by `InAppImageComponent`
/// and `SlideInAppImageComponent`, which only differ in how `width` is computed
/// and in whether the fullscreen image should stretch to fill available width.
protocol InAppImageSizing {
    var config: InAppImageComponentConfig { get }
    var width: CGFloat { get }
}

extension InAppImageSizing {
    func getHeightFromAspectRation(aspectRation: CGSize) -> CGFloat {
        let screenWidth = width
        let aspectRatio: CGFloat = aspectRation.width / aspectRation.height
        return abs(screenWidth / aspectRatio)
    }

    func getHeightFromSize(imageSize: CGSize) -> CGFloat {
        guard imageSize.height > 0, imageSize.width > 0 else { return width }
        let screenWidth = width
        let aspectRatio: CGFloat = imageSize.width / imageSize.height
        return abs(screenWidth / aspectRatio)
    }

    @ViewBuilder
    func imageContent(_ image: Image, imageSize: CGSize, fullscreenFillsWidth: Bool = true) -> some View {
        switch config.size {
        case .auto:
            image
                .resizable()
                .scaledToFill()
                .frame(width: width, height: getHeightFromSize(imageSize: imageSize))
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
                let frameWidth = imageSize.width > 0 ? imageSize.width : width
                let frameHeight = imageSize.height > 0 ? imageSize.height : width
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: frameWidth, height: frameHeight)
                    .position(x: width / 2, y: getHeightFromAspectRation(aspectRation: apectRatio) / 2)
                    .frame(width: width, height: getHeightFromAspectRation(aspectRation: apectRatio))
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: config.cornerRadius ?? 0))
            }
        case .fullscreen:
            if fullscreenFillsWidth {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0)
                    .frame(maxWidth: .infinity)
                    .edgesIgnoringSafeArea(.all)
                    .frame(alignment: .center)
            } else {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0)
                    .edgesIgnoringSafeArea(.all)
                    .frame(alignment: .center)
            }
        }
    }
}
