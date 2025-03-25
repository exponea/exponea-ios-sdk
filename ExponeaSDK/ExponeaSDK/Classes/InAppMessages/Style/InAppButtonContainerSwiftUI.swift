//
//  InAppButtonContainerSwiftUI.swift
//  ExponeaSDK
//
//  Created by Ankmara on 01.11.2024.
//  Copyright © 2024 Exponea. All rights reserved.
//

import SwiftUI

struct InAppButtonContainerSwiftUI: View {

    @ObservedObject var viewModel: InAppButtonContainerSwiftUIViewModel
    private let buttons: [InAppButtonConfig]
    private let alignment: InAppButtonAlignmentType

    init(buttons: [InAppButtonConfig], alignment: InAppButtonAlignmentType) {
        self.buttons = buttons
        self.alignment = alignment
        self.viewModel = .init(input: buttons)
    }

    var body: some View {
        VStack(alignment: alignment.alignment, spacing: 0) {
            ForEach(viewModel.data, id: \.id) { config in
                if config.stackType == .horizontal {
                    HStack(spacing: 0) {
                        switch alignment {
                        case .center:
                            Spacer()
                            buttonsView(buttons: config.buttons)
                            Spacer()
                        case .left:
                            buttonsView(buttons: config.buttons)
                            Spacer()
                        case .right:
                            Spacer()
                            buttonsView(buttons: config.buttons)
                        }
                    }
                } else {
                    if config.buttons[0].layout == .hug {
                        HStack(spacing: 0) {
                            switch alignment {
                            case .center:
                                Spacer()
                                buttonsView(buttons: config.buttons)
                                Spacer()
                            case .left:
                                buttonsView(buttons: config.buttons)
                                Spacer()
                            case .right:
                                Spacer()
                                buttonsView(buttons: config.buttons)
                            }
                        }
                    } else {
                        makeButtonWithConfig(config: config.buttons[0])
                    }
                }
            }
        }
    }
}

private extension InAppButtonContainerSwiftUI {
    func buttonsView(buttons: [InAppButtonConfig]) -> some View {
        ForEach(buttons, id: \.id) { config in
            makeButtonWithConfig(config: config)
        }
    }

    func makeButtonWithConfig(config: InAppButtonConfig) -> some View {
        VStack(spacing: 0) {
            InAppButtonSwiftUI(config: config)
                .clipShape(RoundedRectangle(cornerRadius: config.cornerRadius))
                .padding(.bottom, config.margin.first(where: { $0.edge == .bottom })?.value ?? 0)
                .padding(.top, config.margin.first(where: { $0.edge == .top })?.value ?? 0)
                .padding(.trailing, config.margin.first(where: { $0.edge == .trailing })?.value ?? 0)
                .padding(.leading, config.margin.first(where: { $0.edge == .leading })?.value ?? 0)
        }
    }
}
