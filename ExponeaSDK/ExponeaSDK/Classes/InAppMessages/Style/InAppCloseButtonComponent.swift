//
//  InAppCloseButtonComponent.swift
//  ExponeaSDK
//
//  Created by Ankmara on 05.11.2024.
//  Copyright © 2024 Exponea. All rights reserved.
//

import SwiftUI
import UIKit
import Combine

public struct InAppCloseButton: View {

    public let config: InAppCloseButtonConfig
    private let defaultBackgroundPadding = 8.0
    @State private var uiImage: UIImage?
    @State private var isSVG: Bool = false

    public init(config: InAppCloseButtonConfig) {
        self.config = config
    }

    public var body: some View {
        Button(action: {
            config.dismissCallback?()
        }) {
            VStack(spacing: 0) {
                if let imageURL = config.imageURL, let url = URL(string: imageURL) {
                    if let iconColor = config.iconColor,
                       let color = UIColor.parse(iconColor) {
                        let alpha = CIColor(color: color).alpha
                        let image = ExponeaAsyncImage(url: url) { image in
                            image
                                .resizable()
                                .renderingMode(alpha > 0 ? .template : .original)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: config.size.width, height: config.size.height)
                                .padding(defaultBackgroundPadding)
                        } placeholder: {
                            Color(.clear)
                        }
                        if alpha > 0 {
                            image
                                .foregroundColor(Color(UIColor.parse(iconColor) ?? .clear))
                        } else {
                            image
                        }
                    }
                }
            }
            .background(SwiftUI.Color(UIColor.parse(config.backgroundColor) ?? .clear))
            .clipShape(RoundedRectangle(cornerRadius: config.size.width / 2 + defaultBackgroundPadding))
        }
    }
}
