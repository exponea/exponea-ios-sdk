//
//  InAppButtonSwiftUI.swift
//  ExponeaSDK
//
//  Created by Ankmara on 01.11.2024.
//  Copyright © 2024 Exponea. All rights reserved.
//

import SwiftUI

final class InAppButtonSwiftUIModel {
    var isDownloadingFont = false
}

struct InAppButtonSwiftUI: View {

    var config: InAppButtonConfig
    @State var newFont: Font
    let viewModel = InAppButtonSwiftUIModel()
    @State var height: CGFloat = 0

    init(config: InAppButtonConfig) {
        self.config = config
        self.newFont = Font(UIFont.fromStyle(style: config.style, size: config.size))
    }

    var body: some View {
        Button(action: {
            config.actionCallback?(config.payloadButton)
        }) {
            let font = Font(config.fontData?.loadedFont ?? UIFont.systemFont(ofSize: CGFloat(config.size)))
            let text = SwiftUI.Text(config.title)
                .multilineTextAlignment(config.textAlignment?.textAlignment ?? .center)
                .lineSpacing(config.calculatedLineHeight)
                .foregroundColor(Color(UIColor.parse(config.textColor) ?? .black))
                .font(font)
                .padding(.bottom, config.padding.first(where: { $0.edge == .bottom })?.value ?? 0)
                .padding(.top, config.padding.first(where: { $0.edge == .top })?.value ?? 0)
                .padding(.trailing, config.padding.first(where: { $0.edge == .trailing })?.value ?? 0)
                .padding(.leading, config.padding.first(where: { $0.edge == .leading })?.value ?? 0)
                .lineLimit(nil)
            HStack(spacing: 0) {
                switch config.textAlignment {
                case .left:
                    if config.layout == .fill {
                        text
                        Spacer()
                    } else {
                        text
                    }
                case .center:
                    if config.layout == .fill {
                        Spacer()
                        text
                        Spacer()
                    } else {
                        text
                    }
                case .right:
                    if config.layout == .fill {
                        Spacer()
                        text
                    } else {
                        text
                    }
                case .none:
                    EmptyView()
                }
            }
        }
        .background(Color(UIColor.parse(config.backgroundColor) ?? .clear))
        .overlay(
            RoundedRectangle(cornerRadius: config.cornerRadius)
            .stroke(
                Color(
                    config.isBorderEnabled ? UIColor.parse(config.borderColor) ?? .clear : .clear
                ),
                lineWidth: config.isBorderEnabled ? config.borderWeight : 0
            )
        )
    }
}
