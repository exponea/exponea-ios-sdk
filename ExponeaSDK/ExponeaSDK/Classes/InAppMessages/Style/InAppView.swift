//
//  InAppView.swift
//  ExponeaSDK
//
//  Created by Ankmara on 13.11.2024.
//  Copyright © 2024 Exponea. All rights reserved.
//

import SwiftUI
import UIKit

public struct InAppView: View {

    public let layouConfig: InAppLayoutConfig
    public let buttonsConfig: [InAppButtonConfig]
    public let titleConfig: InAppLabelConfig
    public let bodyConfig: InAppBodyLabelConfig
    public let closeButtonConfig: InAppCloseButtonConfig
    public let imageConfig: InAppImageComponentConfig
    public var textCompletionHeight: TypeBlock<CGFloat>?
    @ObservedObject var config: InAppViewConfig = .init()
    private let preloadedImage: UIImage?
    private let isFullscreen: Bool

    private var isTextVisible: Bool {
        titleConfig.isVisible || bodyConfig.isVisible
    }

    init(
        layouConfig: InAppLayoutConfig,
        buttonsConfig: [InAppButtonConfig],
        titleConfig: InAppLabelConfig,
        bodyConfig: InAppBodyLabelConfig,
        closeButtonConfig: InAppCloseButtonConfig,
        imageConfig: InAppImageComponentConfig,
        preloadedImage: UIImage? = nil,
        isFullscreen: Bool
    ) {
        self.layouConfig = layouConfig
        self.buttonsConfig = buttonsConfig
        self.titleConfig = titleConfig
        self.bodyConfig = bodyConfig
        self.closeButtonConfig = closeButtonConfig
        self.imageConfig = imageConfig
        self.preloadedImage = preloadedImage
        self.isFullscreen = isFullscreen
    }

    private var width: CGFloat {
        let trailing = layouConfig.margin.first(where: { $0.edge == .trailing })?.value ?? 0
        let leading = layouConfig.margin.first(where: { $0.edge == .leading })?.value ?? 0
        let paddingTrailing = layouConfig.padding.first(where: { $0.edge == .trailing })?.value ?? 0
        let paddingLeading = layouConfig.padding.first(where: { $0.edge == .leading })?.value ?? 0
        return UIScreen.main.bounds.width - trailing - leading - paddingTrailing - paddingLeading
    }

    private var titleWidth: CGFloat {
        let trailing = titleConfig.padding.first(where: { $0.edge == .trailing })?.value ?? 0
        let leading = titleConfig.padding.first(where: { $0.edge == .leading })?.value ?? 0
        return width - trailing - leading
    }

    private var bodyWidth: CGFloat {
        let trailing = bodyConfig.padding.first(where: { $0.edge == .trailing })?.value ?? 0
        let leading = bodyConfig.padding.first(where: { $0.edge == .leading })?.value ?? 0
        return width - trailing - leading
    }

    private var footer: some View {
        VStack(spacing: 0) {
            buttonArea
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            if !config.shouldBeScrollable {
                imageArea
            }
            if isTextVisible {
                textArea
            } else {
                VStack(spacing: 0) {}
                    .frame(width: 600)
            }
        }
    }

    private var upSideDownContent: some View {
        VStack(spacing: 0) {
            if isTextVisible {
                textArea
            } else {
                VStack(spacing: 0) {}
                    .frame(width: 600)
            }
        }
    }

    private var imageArea: some View {
        VStack(spacing: 0) {
            InAppImageComponent(
                config: imageConfig,
                layoutConfig: layouConfig,
                preloadedImage: preloadedImage
            )
        }
    }

    private var buttonArea: some View {
        InAppButtonContainerSwiftUI(
            buttons: buttonsConfig,
            alignment: layouConfig.buttonsAlign
        )
    }

    private var textArea: some View {
        VStack(spacing: 0) {
            if titleConfig.isVisible {
                TextWithAttributedString(
                    config: titleConfig,
                    width: titleWidth
                )
            }
            if bodyConfig.isVisible {
                TextWithAttributedString(
                    config: bodyConfig,
                    width: bodyWidth
                )
            }
            if isFullscreen && (layouConfig.textPosition == .top || layouConfig.textPosition == .bottom) && !config.shouldBeScrollable {
                Spacer()
            }
        }
    }

    var imageOnly: some View {
        VStack(spacing: 0) {
            if imageConfig.isVisible {
                InAppImageComponent(
                    config: imageConfig,
                    layoutConfig: layouConfig,
                    preloadedImage: preloadedImage
                )
                .padding(.bottom, imageConfig.margin.first(where: { $0.edge == .bottom })?.value ?? 0)
                .padding(.top, imageConfig.margin.first(where: { $0.edge == .top })?.value ?? 0)
                .padding(.trailing, imageConfig.margin.first(where: { $0.edge == .trailing })?.value ?? 0)
                .padding(.leading, imageConfig.margin.first(where: { $0.edge == .leading })?.value ?? 0)
            }
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            switch true {
            case imageConfig.size == .fullscreen && imageConfig.isVisible:
                ZStack {
                    imageArea
                        .zIndex(1)
                    if imageConfig.isOverlay, let overlayColor = imageConfig.overlayColor {
                        Color(UIColor.parse(overlayColor) ?? .clear)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .zIndex(2)
                    }
                    VStack(spacing: 0) {
                        if isTextVisible {
                            textArea
                        } else {
                            VStack(spacing: 0) {}
                                .frame(width: 600)
                        }
                        if isFullscreen && !config.shouldBeScrollable {
                            Spacer()
                        }
                        footer
                    }
                    .zIndex(3)
                    .padding(.bottom, layouConfig.padding.first(where: { $0.edge == .bottom })?.value ?? 0)
                    .padding(.top, layouConfig.padding.first(where: { $0.edge == .top })?.value ?? 0)
                    .padding(.trailing, layouConfig.padding.first(where: { $0.edge == .trailing })?.value ?? 0)
                    .padding(.leading, layouConfig.padding.first(where: { $0.edge == .leading })?.value ?? 0)
                }
            case config.shouldBeScrollable:
                if layouConfig.textPosition == .top {
                    VStack(spacing: 0) {
                        ScrollView(showsIndicators: false) {
                            textArea
                            imageOnly
                        }
                        footer
                    }
                    .padding(.bottom, layouConfig.padding.first(where: { $0.edge == .bottom })?.value ?? 0)
                    .padding(.top, layouConfig.padding.first(where: { $0.edge == .top })?.value ?? 0)
                    .padding(.trailing, layouConfig.padding.first(where: { $0.edge == .trailing })?.value ?? 0)
                    .padding(.leading, layouConfig.padding.first(where: { $0.edge == .leading })?.value ?? 0)
                } else {
                    VStack(spacing: 0) {
                        ScrollView(showsIndicators: false) {
                            imageOnly
                            textArea
                        }
                        footer
                    }
                    .padding(.bottom, layouConfig.padding.first(where: { $0.edge == .bottom })?.value ?? 0)
                    .padding(.top, layouConfig.padding.first(where: { $0.edge == .top })?.value ?? 0)
                    .padding(.trailing, layouConfig.padding.first(where: { $0.edge == .trailing })?.value ?? 0)
                    .padding(.leading, layouConfig.padding.first(where: { $0.edge == .leading })?.value ?? 0)
                }
            case layouConfig.textPosition == .bottom:
                VStack(spacing: 0) {
                    imageOnly
                    textArea
                    footer
                }
                .padding(.bottom, layouConfig.padding.first(where: { $0.edge == .bottom })?.value ?? 0)
                .padding(.top, layouConfig.padding.first(where: { $0.edge == .top })?.value ?? 0)
                .padding(.trailing, layouConfig.padding.first(where: { $0.edge == .trailing })?.value ?? 0)
                .padding(.leading, layouConfig.padding.first(where: { $0.edge == .leading })?.value ?? 0)
            case layouConfig.textPosition == .top:
                VStack(spacing: 0) {
                    textArea
                    imageOnly
                    footer
                }
                .padding(.bottom, layouConfig.padding.first(where: { $0.edge == .bottom })?.value ?? 0)
                .padding(.top, layouConfig.padding.first(where: { $0.edge == .top })?.value ?? 0)
                .padding(.trailing, layouConfig.padding.first(where: { $0.edge == .trailing })?.value ?? 0)
                .padding(.leading, layouConfig.padding.first(where: { $0.edge == .leading })?.value ?? 0)
            default:
                EmptyView()
            }
        }
        .background(Color(UIColor.parse(layouConfig.backgroundColor) ?? .clear))
        .inAppCloseButtonOverlay(config: closeButtonConfig)
        .readHeight { height in
            self.config.height = height
        }
        .onAppear {
            config.textCompletionHeight = { height in
                self.textCompletionHeight?(height)
            }
        }
    }
}
